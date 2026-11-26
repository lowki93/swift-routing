//
//  NavigationRestorationStore.swift
//  swift-routing
//

import Combine
import Foundation

/// Holds the saved navigation of one scene, hands it out to the routers built from it, and snapshots the live tree.
///
/// Routers can be built off the main actor (see `ConcurrencyTests`), so every access to the mutable
/// state goes through `lock`.
final class NavigationRestorationStore: @unchecked Sendable {

  typealias RestorationReason = RouterError.RestorationReason

  /// Called with the reason when a container's route types are not `Codable` and `shouldCrashOnRouteNotFound` is on.
  /// A decoding failure never calls it.
  /// Injectable so the crash is testable.
  typealias FailureHook = @Sendable (String) -> Void

  /// The state a router starts with, and what to report about it.
  struct Restoration {
    var state: RestoredState?
    var reasons: [RestorationReason] = []
    var crash: (() -> Void)?

    static var unrestored: Restoration { Restoration() }
  }

  struct RestoredState {
    var root: AnyRoute?
    var path: [AnyRoute]
    var sheet: AnyRoute?
    var cover: AnyRoute?
    /// The saved tab of a `TabRouter`, `nil` when none was saved or it no longer decodes.
    var tab: AnyRoute?
  }

  /// What the store knew when a save started, read once so the walk of the live tree holds no lock.
  private struct History {
    let used: Set<[String]>
    let failed: Set<[String]>
    let screensGone: Set<[String]>

    func isFailed(_ path: [String]) -> Bool {
      failed.contains { path.starts(with: $0) }
    }
  }

  private struct LogKey: Hashable {
    let path: [String]
    let kind: String
  }

  private let lock = NSLock()
  private var _snapshot: NavigationSnapshot
  /// Paths whose node was handed out already: a router built later at the same path starts on its default state.
  private var used: Set<[String]> = []
  /// Paths that failed to decode, or that belong to a modal the user presented fresh: they and
  /// their subtree start on their default state.
  private var failed: Set<[String]> = []
  /// Paths of stacks seeded from the snapshot that later left their restored screens (a pop, a root change,
  /// a deeplink): the nested containers saved under them are never seeded nor kept.
  private var screensGone: Set<[String]> = []
  private var logged: Set<LogKey> = []
  private var loadFailure: RestorationReason?
  private let failureHook: FailureHook

  /// Fires after ``clear()``, so the owner of the persisted copy can erase it.
  let cleared = PassthroughSubject<Void, Never>()

  init(snapshot: NavigationSnapshot = .empty, failureHook: @escaping FailureHook = { fatalError($0) }) {
    self._snapshot = snapshot
    self.failureHook = failureHook
  }

  /// Loads the data written by a previous save. Corrupt data or an unknown `version` discards
  /// the whole snapshot; the failure is reported once by ``takeLoadFailure()``.
  init(data: Data?, failureHook: @escaping FailureHook = { fatalError($0) }) {
    self.failureHook = failureHook
    guard let data else {
      self._snapshot = .empty
      return
    }
    do {
      let decoded = try JSONDecoder().decode(NavigationSnapshot.self, from: data)
      if decoded.version == NavigationSnapshot.currentVersion {
        self._snapshot = decoded
      } else {
        self._snapshot = .empty
        self.loadFailure = .decodingFailed(container: Self.name(of: []), error: "unknown snapshot version \(decoded.version)")
      }
    } catch {
      self._snapshot = .empty
      self.loadFailure = .decodingFailed(container: Self.name(of: []), error: String(describing: error))
    }
  }

  var snapshot: NavigationSnapshot {
    lock.withLock { _snapshot }
  }

  /// The error that made the store discard its data at creation, returned once.
  func takeLoadFailure() -> RestorationReason? {
    lock.withLock {
      defer { loadFailure = nil }
      return loadFailure
    }
  }

  static func encode(_ snapshot: NavigationSnapshot) throws -> Data {
    try RestorationCodec.makeEncoder().encode(snapshot)
  }

  static func name(of path: [String]) -> String {
    path.isEmpty ? "snapshot" : path.joined(separator: "/")
  }

  // MARK: - Clearing

  /// Empties the in-memory snapshot and signals ``cleared``.
  ///
  /// Routers built afterwards start on their default state. It does not block later saves.
  func clear() {
    lock.withLock { _snapshot = .empty }
    cleared.send()
  }

  // MARK: - Seeding

  /// Looks up the saved state for the container at `path` and consumes it.
  ///
  /// Pure with respect to the router: it only reads and marks the store, the caller logs `reasons`
  /// and runs `crash`. An orphan node is never asked for, so it is ignored without a trace.
  func restore(at path: [String], schema: RestorationSchema, crashOnNotCodable: Bool) -> Restoration {
    lock.withLock {
      if let type = schema.firstNonCodable {
        let reason = RestorationReason.notCodable(container: Self.name(of: path), type: RestorationCodec.name(of: type))
        let reasons = shouldLog(path, "notCodable") ? [reason] : []
        let hook = failureHook
        return Restoration(state: nil, reasons: reasons, crash: crashOnNotCodable ? { hook(reason.description) } : nil)
      }
      guard path.first == _snapshot.rootSegment, !isFailed(path), used.insert(path).inserted,
        let state = _snapshot.root.node(at: path.dropFirst())?.state
      else { return .unrestored }
      do {
        let root = try state.root.map { try schema.decodeRoute($0) }
        let routes = try state.path.map { try schema.decodeRoute($0) }
        // An undecodable modal only costs the modal: the host keeps its root and path.
        let sheet = decodeModal(state.sheet, slot: .sheet, at: path, schema: schema)
        let cover = decodeModal(state.cover, slot: .cover, at: path, schema: schema)
        // An undecodable tab (a removed case) only costs the selection: the stacks of the tabs are
        // other containers, restored on their own.
        let tab = decodeTab(state.tab, at: path, schema: schema)
        return Restoration(
          state: RestoredState(root: root, path: routes, sheet: sheet.route, cover: cover.route, tab: tab.route),
          reasons: [sheet.reason, cover.reason, tab.reason].compactMap { $0 }
        )
      } catch {
        failed.insert(path)
        let reason = RestorationReason.decodingFailed(container: Self.name(of: path), error: String(describing: error))
        return Restoration(state: nil, reasons: shouldLog(path, "decodingFailed") ? [reason] : [])
      }
    }
  }

  /// Starts the container at `path`, and everything below it, on its default state.
  ///
  /// Used for a modal the user presented fresh: no saved node may seed it, nor a container nested in it.
  func discard(at path: [String]) {
    lock.withLock { _ = failed.insert(path) }
  }

  /// Records that the stack at `path`, seeded from the snapshot, left its restored screens.
  ///
  /// Sticky: pushing an equal screen again does not bring the saved nested containers back.
  func markRestoredScreensGone(under path: [String]) {
    lock.withLock { _ = screensGone.insert(path) }
  }

  /// Decodes a saved modal route. Callers hold `lock`.
  private func decodeModal(
    _ stored: StoredRoute?,
    slot: ModalSlot,
    at path: [String],
    schema: RestorationSchema
  ) -> (route: AnyRoute?, reason: RestorationReason?) {
    guard let stored else { return (nil, nil) }
    do {
      return (try schema.decodeRoute(stored), nil)
    } catch {
      let modalPath = path.dropLast() + [(path.last ?? "") + "#\(slot.rawValue)"]
      let reason = RestorationReason.decodingFailed(container: Self.name(of: Array(modalPath)), error: String(describing: error))
      return (nil, shouldLog(Array(modalPath), "decodingFailed") ? reason : nil)
    }
  }

  /// Decodes the saved tab of the `TabRouter` at `path`. Callers hold `lock`.
  private func decodeTab(
    _ stored: StoredRoute?,
    at path: [String],
    schema: RestorationSchema
  ) -> (route: AnyRoute?, reason: RestorationReason?) {
    guard let stored else { return (nil, nil) }
    do {
      return (try schema.decodeRoute(stored), nil)
    } catch {
      let reason = RestorationReason.decodingFailed(container: Self.name(of: path), error: String(describing: error))
      return (nil, shouldLog(path, "decodingFailed") ? reason : nil)
    }
  }

  // MARK: - Saving

  /// Walks the live tree from `root` and returns what it holds right now, merged with the saved nodes
  /// of containers that were never built.
  ///
  /// Skips routers that left the screen, presented routers that are not their parent's current sheet
  /// or cover (so a pending or dismissing modal is never saved), and non-restorable routers. Siblings sharing a segment are not saved.
  ///
  /// The merge keeps a saved node without a live router only when it was never handed out (the stack of a
  /// tab the user did not visit), is not a modal its live host no longer shows, is not nested in a stack that left its restored
  /// screens, and is not under a failed path.
  /// A live node always wins.
  @MainActor
  func snapshot(from root: BaseRouter) -> NavigationSnapshot {
    let (stored, history) = lock.withLock { (_snapshot, History(used: used, failed: failed, screensGone: screensGone)) }
    let storedRoot = stored.rootSegment == root.restorationSegment ? stored.root : nil
    let node = node(of: root, at: [root.restorationSegment], stored: storedRoot, history: history) ?? RestorationNode()
    return NavigationSnapshot(version: NavigationSnapshot.currentVersion, rootSegment: root.restorationSegment, root: node)
  }

  /// The data to persist for the live tree under `root`: what exists right now, encoded deterministically.
  @MainActor
  func save(from root: BaseRouter) throws -> Data {
    try Self.encode(snapshot(from: root))
  }

  @MainActor
  private func node(of router: BaseRouter, at path: [String], stored: RestorationNode?, history: History) -> RestorationNode? {
    var node = RestorationNode()
    do {
      node.state = try state(of: router)
    } catch {
      // Only this container's own state is lost: its children are still saved.
      if lock.withLock({ shouldLog(path, "encodingFailed") }) {
        router.log(.error(.restoration(.encodingFailed(container: Self.name(of: path), error: String(describing: error)))))
      }
    }

    let routers = router.children.values.compactMap(\.value)
    let live = routers.filter { isSaved($0, in: router) }
    // A router that exists but is not saved (left the screen, pending) still hides its stored node.
    let liveSegments = Set(routers.map(\.restorationSegment))
    for (segment, siblings) in Dictionary(grouping: live, by: \.restorationSegment) {
      let childPath = path + [segment]
      guard siblings.count == 1 else {
        if lock.withLock({ shouldLog(childPath, "duplicateKey") }) {
          router.log(.error(.restoration(.duplicateKey(container: Self.name(of: childPath)))))
        }
        continue
      }
      node.children[segment] = self.node(of: siblings[0], at: childPath, stored: stored?.children[segment], history: history)
    }

    for (segment, storedChild) in stored?.children ?? [:] where !liveSegments.contains(segment) {
      let childPath = path + [segment]
      if let slot = Self.modalSlot(of: segment) {
        guard Self.showsSameModal(slot, live: node.state, stored: stored?.state) else { continue }
      } else if history.screensGone.contains(path) {
        // A container nested in a screen of a stack that left its restored screens.
        continue
      }
      // shortcut: the node of a renamed tab type or of a removed tab case stays as stale bytes until
      // `clearNavigationRestoration()`, as nothing asks for it again and telling it apart needs the list
      // of tab cases; upgrade if the stale data on disk becomes a problem.
      node.children[segment] = surviving(storedChild, at: childPath, history: history)
    }
    return node.isEmpty ? nil : node
  }

  /// The saved node, without what a router already consumed or what sits under a failed path.
  private func surviving(_ node: RestorationNode, at path: [String], history: History) -> RestorationNode? {
    guard !history.used.contains(path), !history.isFailed(path) else { return nil }
    var kept = node
    kept.children = [:]
    for (segment, child) in node.children {
      kept.children[segment] = surviving(child, at: path + [segment], history: history)
    }
    return kept.isEmpty ? nil : kept
  }

  /// The slot a presented router's segment (`presented(name)#sheet`) stands for.
  private static func modalSlot(of segment: String) -> ModalSlot? {
    guard segment.hasPrefix("presented(") else { return nil }
    return [ModalSlot.sheet, .cover].first { segment.hasSuffix("#\($0.rawValue)") }
  }

  /// Whether the live host still shows the modal it showed when the node was saved. A modal that was
  /// dismissed or replaced leaves a stale node, which must not come back.
  private static func showsSameModal(_ slot: ModalSlot, live: RouterState?, stored: RouterState?) -> Bool {
    let liveRoute = slot == .sheet ? live?.sheet : live?.cover
    let storedRoute = slot == .sheet ? stored?.sheet : stored?.cover
    return liveRoute != nil && liveRoute == storedRoute
  }

  /// Whether the container about to be built under `parent` may use its saved node: not when `parent`, a stack,
  /// left the screens it was restored with (a pop or a deeplink in between leaves the node stale).
  func allowsSeeding(under parent: BaseRouter) -> Bool {
    guard parent is Router else { return true }
    let path = parent.restorationPath
    return lock.withLock { !screensGone.contains(path) }
  }

  /// What `router` contributes to a snapshot, `nil` when its container takes no part in restoration.
  @MainActor
  private func state(of router: BaseRouter) throws -> RouterState? {
    if let router = router as? Router, let schema = router.restorationSchema, schema.firstNonCodable == nil {
      return RouterState(
        root: try RestorationCodec.encode(router.root),
        path: try router.path.map(RestorationCodec.encode),
        sheet: try router.sheet.map(RestorationCodec.encode),
        cover: try router.cover.map(RestorationCodec.encode)
      )
    }
    if let router = router as? TabRouter, router.restorationSchema.firstNonCodable == nil {
      return RouterState(tab: try RestorationCodec.encode(AnyRoute(wrapped: router.tab.wrapped)))
    }
    return nil
  }

  @MainActor
  private func isSaved(_ child: BaseRouter, in parent: BaseRouter) -> Bool {
    guard let router = child as? Router else { return true }
    guard !router.hasLeftScreen else { return false }
    guard router.isPresented else { return true }
    guard router.restorationSchema != nil else { return false }
    guard let parent = parent as? Router else { return false }
    // Only the router showing the parent's current sheet or cover, in its own slot.
    let current = router.modalSlot.map { [$0 == .sheet ? parent.sheet : parent.cover] } ?? [parent.sheet, parent.cover]
    return [router].presenting(current.compactMap { $0 }) != nil
  }

  // MARK: - Helpers

  private func isFailed(_ path: [String]) -> Bool {
    failed.contains { path.starts(with: $0) }
  }

  /// `true` the first time `kind` is reported for `path`. Callers hold `lock`.
  private func shouldLog(_ path: [String], _ kind: String) -> Bool {
    logged.insert(LogKey(path: path, kind: kind)).inserted
  }
}
