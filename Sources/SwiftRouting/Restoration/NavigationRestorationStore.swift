//
//  NavigationRestorationStore.swift
//  swift-routing
//

import Foundation

typealias RestorationReason = RouterError.RestorationReason

/// Holds the saved navigation of one scene, hands it out to the routers built from it, and snapshots the live tree.
///
/// Routers can be built off the main actor (see `ConcurrencyTests`), so every access to the mutable
/// state goes through `lock`.
final class NavigationRestorationStore: @unchecked Sendable {

  /// Called with the reason when a container cannot be restored and `shouldCrashOnRouteNotFound` is on.
  /// Injectable so the crash is testable.
  typealias FailureHook = @Sendable (String) -> Void

  /// The state a router starts with, and what to report about it.
  struct Restoration {
    var state: RestoredState?
    var reasons: [RestorationReason] = []
    var crash: (() -> Void)?

    static var none: Restoration { Restoration() }
  }

  struct RestoredState {
    var root: AnyRoute?
    var path: [AnyRoute]
  }

  private struct LogKey: Hashable {
    let path: [String]
    let kind: String
  }

  private let lock = NSLock()
  private var _snapshot: NavigationSnapshot
  /// Paths whose node was handed out already: a router built later at the same path starts on its default state.
  private var used: Set<[String]> = []
  /// Paths that failed to decode: they and their subtree start on their default state.
  private var failed: Set<[String]> = []
  private var logged: Set<LogKey> = []
  private var loadFailure: RestorationReason?
  private let failureHook: FailureHook

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
      guard !isFailed(path), used.insert(path).inserted,
        let state = _snapshot.root.node(at: path.dropFirst())?.state
      else { return .none }
      do {
        let root = try state.root.map { try schema.decodeRoute($0) }
        let routes = try state.path.map { try schema.decodeRoute($0) }
        return Restoration(state: RestoredState(root: root, path: routes))
      } catch {
        failed.insert(path)
        let reason = RestorationReason.decodingFailed(container: Self.name(of: path), error: String(describing: error))
        return Restoration(state: nil, reasons: shouldLog(path, "decodingFailed") ? [reason] : [])
      }
    }
  }

  // MARK: - Saving

  /// Walks the live tree from `root` and returns what it holds right now.
  ///
  /// Skips routers that left the screen, presented routers that are not their parent's current sheet
  /// or cover, and non-restorable routers. Siblings sharing a segment are not saved.
  func snapshot(from root: BaseRouter) -> NavigationSnapshot {
    let node = node(of: root, at: [root.restorationSegment]) ?? RestorationNode()
    return NavigationSnapshot(version: NavigationSnapshot.currentVersion, root: node)
  }

  private func node(of router: BaseRouter, at path: [String]) -> RestorationNode? {
    var node = RestorationNode()
    if let router = router as? Router, let schema = router.restorationSchema, schema.firstNonCodable == nil {
      do {
        node.state = try state(of: router)
      } catch {
        if lock.withLock({ shouldLog(path, "encodingFailed") }) {
          router.log(.error(.restoration(.encodingFailed(container: Self.name(of: path), error: String(describing: error)))))
        }
        return nil
      }
    }

    let live = router.children.values.compactMap(\.value).filter { isSaved($0, in: router) }
    for (segment, siblings) in Dictionary(grouping: live, by: \.restorationSegment) {
      let childPath = path + [segment]
      guard siblings.count == 1 else {
        if lock.withLock({ shouldLog(childPath, "duplicateKey") }) {
          router.log(.error(.restoration(.duplicateKey(container: Self.name(of: childPath)))))
        }
        continue
      }
      node.children[segment] = self.node(of: siblings[0], at: childPath)
    }
    return node.isEmpty ? nil : node
  }

  private func state(of router: Router) throws -> RouterState {
    RouterState(
      root: try RestorationCodec.encode(router.root),
      path: try router.path.map(RestorationCodec.encode)
    )
  }

  private func isSaved(_ child: BaseRouter, in parent: BaseRouter) -> Bool {
    guard let router = child as? Router else { return true }
    guard !router.hasLeftScreen else { return false }
    guard router.isPresented else { return true }
    guard let parent = parent as? Router else { return false }
    return [router].presenting([parent.sheet, parent.cover].compactMap { $0 }) != nil
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
