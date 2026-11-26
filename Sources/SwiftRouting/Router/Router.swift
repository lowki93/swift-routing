//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI

/// Manages programmatic navigation for both stack-based and split-view contexts.
///
/// Each `RoutingView` and `RoutingSplitView` creates its own `Router`. Its kind —
/// stack, tab, presented, or split — is not public API, but shows up in ``BaseRouter/description``
/// (and therefore in log output) as `stack(...)`, `tab(...)`, `presented(...)`, or `split(...)`.
///
/// ## Stack navigation
/// ```swift
/// @Environment(\.router) var router
///
/// router.push(HomeRoute.page2)
/// router.present(HomeRoute.settings)
/// router.pop()
/// ```
///
/// ## Split view navigation
///
/// Inside a `RoutingSplitView`, `\(router)` is the split router. Use it to drive
/// column selections instead of push navigation:
/// ```swift
/// @Environment(\.router) var router
///
/// router.select(detail: player)          // drives the detail column
/// router.select(content: playerType)     // drives the content column (3-column only)
/// ```
public final class Router: BaseRouter, @unchecked Sendable {

  static let defaultRouter: Router = Router(configuration: .default)

  // MARK: Navigation
  @Published internal var path: [AnyRoute] = [] {
    willSet {
      removeContext(old: path, new: newValue)
    }
    didSet {
      if let restoredPath, !path.starts(with: restoredPath) { restoredScreensGone() }
      // `NavigationStack(path: $router.path)` (in `RoutingView`/`RoutingSplitView`) lets
      // SwiftUI mutate `path` directly through the binding -- bypassing push(_:)/pop()/
      // popToRoot()/terminate(_:) entirely -- for a native `NavigationLink` push, a
      // swipe-back/back-button tap, or a long-press-back-button jump to an ancestor. Their
      // explicit `log(...)` calls never run for those, so this observer is the single place
      // that catches both native and programmatic changes to `path`.
      let delta = path.count - oldValue.count
      if delta > 0, let pushed = path.last {
        // Not just `oldValue.last?.wrapped ?? root.wrapped`: for a split router with an
        // empty `path`, "current" before this push was whatever `currentRoute` itself would
        // have resolved to -- the detail or content selection, not necessarily `root`.
        log(.navigation(from: route(for: oldValue).wrapped, to: pushed.wrapped, type: .push))
      } else if delta < 0, !isPathChangeLoggedExplicitly {
        // `isPathChangeLoggedExplicitly` is set by pop()/popToRoot()/terminate(_:) around
        // their own mutation, so a shrink they already logged with more specific semantics
        // (`.popToRoot`, or a `.pop(count:)` tied to a matched context) isn't logged again
        // here -- this only fires for a shrink that didn't go through any of them.
        log(.action(.pop(count: -delta)))
      }
    }
  }

  /// See `path`'s `didSet` for why this exists.
  private var isPathChangeLoggedExplicitly = false

  // MARK: Presentation

  /// The route currently presented as a sheet, or `nil` if no sheet is shown.
  @Published internal var sheet: AnyRoute? {
    didSet {
      guard oldValue != sheet else { return }
      forgetRestoredModal(.sheet)
      // Before `present.send`: an observer reacting to `false` may request the next modal right away.
      modalSlotChanged(from: oldValue, to: sheet)
      present.send((sheet != nil, self))
      logCloseIfNeeded(from: oldValue, to: sheet)
    }
  }

  /// The route currently presented as a full-screen cover, or `nil` if none is shown.
  @Published internal var cover: AnyRoute? {
    didSet {
      guard oldValue != cover else { return }
      forgetRestoredModal(.cover)
      modalSlotChanged(from: oldValue, to: cover)
      present.send((cover != nil, self))
      logCloseIfNeeded(from: oldValue, to: cover)
    }
  }

  /// The presented child animating out: UIKit drops a modal presented before it is gone.
  private weak var dismissingChild: Router?

  /// The latest sheet or cover requested while `dismissingChild` was set.
  private var pendingModal: PendingModal?

  private enum PendingModal {
    case sheet(AnyRoute)
    case cover(AnyRoute)
  }

  /// Set once the parent stops showing this router, so a leftover router never counts as on screen.
  private(set) var hasLeftScreen = false

  /// Triggers dismissal of the current modal when set to `true`.
  @Published internal var triggerClose: Bool = false

  /// Set by `close()` right before it logs its own `.action(.close)` on `self`, so
  /// `logCloseIfNeeded` -- triggered later, on the *parent*, once `sheet`/`cover` actually
  /// clears via `CloseModifier`'s native `dismiss()` -- knows not to log a second time.
  private var isCloseLoggedExplicitly = false

  /// The currently visible route.
  ///
  /// - For **stack** routers: the last pushed route, or the root if the stack is empty.
  /// - For **split** routers: the active detail route resolved from `detailSelection`,
  ///   or the active content route from `contentSelection`, or the sidebar root if
  ///   no column is selected yet.
  ///
  /// ```swift
  /// print(router.currentRoute.name)
  /// ```
  override public var currentRoute: AnyRoute {
    route(for: path)
  }

  /// Resolves the visible route for a given `path` snapshot, following the same rules as
  /// ``currentRoute``. Factored out so `path`'s `didSet` can resolve what was current
  /// *before* a mutation (passing `oldValue`) without duplicating the split-specific
  /// detail/content fallback logic.
  private func route(for path: [AnyRoute]) -> AnyRoute {
    switch type {
    case .split:
      if let route = path.last { return route }
      if let details = detailSelection, let route = detailRouteFactory?(details) { return route }
      if let content = contentSelection, let route = contentRouteFactory?(content) { return route }
      return root
    default:
      return path.last ?? root
    }
  }

  override public var pathCount: Int { path.count }

  /// Indicates whether this router is presented as a modal (sheet or cover).
  ///
  /// Returns `true` if the router was created via `present(_:)` or `cover(_:)`,
  /// `false` for routers created via `push(_:)` or as root/tab routers.
  ///
  /// Use this property to conditionally show close buttons or handle dismissal:
  ///
  /// ```swift
  /// if router.isPresented {
  ///   Button("Close") { router.close() }
  /// }
  /// ```
  public var isPresented: Bool {
    type.isPresented
  }

  /// The total number of routes in the navigation stack, including the root.
  ///
  /// This count includes the root view plus all pushed routes.
  /// A value of 1 means only the root is displayed.
  ///
  /// ```swift
  /// if router.routeCount > 1 {
  ///   // Show back button
  /// }
  /// ```
  public var routeCount: Int {
    switch type {
    case .split:
      return 1
        + (contentSelection != nil ? 1 : 0)
        + (detailSelection != nil ? 1 : 0)
        + path.count
    default:
      return path.count + 1
    }
  }

  // MARK: Configuration
  let type: RouterType

  // MARK: Restoration

  /// The slot of the parent this router is presented in, `nil` for a router that is not presented.
  let modalSlot: ModalSlot?

  /// What this router's container knows about its types, `nil` when it takes no part in restoration.
  let restorationSchema: RestorationSchema?

  /// Guards `restoredModals`, read by a presented child built from `init`, off the main actor.
  private let restoredModalsLock = NSLock()

  /// The sheet and cover this router was seeded with and whose presented child is not built yet.
  /// Only a child built for one of them may use its saved node, and the entry goes with the first
  /// change of the slot, so a modal presented later starts on its default state.
  private var restoredModals: [ModalSlot: AnyRoute] = [:]

  /// The path this router was seeded with, until its stack first changes below it.
  /// Read and written from the main actor, after `init`.
  private var restoredPath: [AnyRoute]?

  /// The first change of the stack below the restored screens: the nested containers saved under
  /// them are stale for good, even if an equal screen is pushed again.
  private func restoredScreensGone() {
    restoredPath = nil
    restorationStore?.markRestoredScreensGone(under: restorationPath)
  }

  override func rootDidChange() {
    if restoredPath != nil { restoredScreensGone() }
  }

  override var restorationSegment: String {
    Self.restorationSegment(type: type, modalSlot: modalSlot)
  }

  private static func restorationSegment(type: RouterType, modalSlot: ModalSlot?) -> String {
    modalSlot.map { "\(type)#\($0.rawValue)" } ?? "\(type)"
  }

  // MARK: Initialization
  /// Initializes a `Router` with a custom configuration.
  ///
  /// This initializer sets up the router with a specified `Configuration`, defining behaviors such as logging.
  /// By default, the router type is set to `.app`, and an initialization log entry is created.
  ///
  /// - Parameter configuration: The configuration used to customize the router's behavior.
  public init(configuration: Configuration) {
    self.type = .app
    self.modalSlot = nil
    self.restorationSchema = nil
    super.init(configuration: configuration, root: AnyRoute(wrapped: DefaultRoute.main), first: true)
  }

  // MARK: Split navigation state

  @Published public internal(set) var detailSelection: AnyHashable?
  @Published public internal(set) var contentSelection: AnyHashable?

  /// Whether the split view is currently in compact (single-column) mode.
  ///
  /// `true` on iPhone at launch and whenever `horizontalSizeClass` becomes `.compact`
  /// (e.g. during iPad multitasking). Always `false` for non-split routers.
  ///
  /// Use this to adapt sidebar behaviour — e.g. skip auto-selection on iPhone so the
  /// user's first tap triggers navigation rather than a silent highlight.
  ///
  /// ```swift
  /// .onFirstAppear {
  ///   guard !router.isCompact else { return }
  ///   router.select(detail: items.first)
  /// }
  /// ```
  @Published public var isCompact: Bool = false

  /// Whether this split router was created with a content column (3-column layout).
  ///
  /// `true` when `RoutingSplitView` was initialised with a `content:` closure.
  /// Always `false` for 2-column layouts and non-split routers.
  ///
  /// ```swift
  /// if router.hasContentColumn {
  ///   router.select(content: playerType)
  /// } else {
  ///   router.select(detail: playerType)
  /// }
  /// ```
  public var hasContentColumn: Bool {
    if case .split(_, let has) = type { return has }
    return false
  }

  public var detailRouteFactory: ((AnyHashable) -> AnyRoute?)?
  public var contentRouteFactory: ((AnyHashable) -> AnyRoute?)?

  init(
    root: AnyRoute,
    type: RouterType,
    parent: BaseRouter,
    isCompact: Bool = false,
    detailRouteFactory: ((AnyHashable) -> AnyRoute?)? = nil,
    contentRouteFactory: ((AnyHashable) -> AnyRoute?)? = nil,
    modalSlot: ModalSlot? = nil,
    schema: RestorationSchema? = nil
  ) {
    self.type = type
    self.modalSlot = modalSlot
    self.restorationSchema = schema
    self.detailRouteFactory = detailRouteFactory
    self.contentRouteFactory = contentRouteFactory

    // Seed through the backing storage and the superclass initializer: the `path` observers, the
    // `.navigation` log, `present` and `events` stay silent, only `.create` is logged.
    let restoration = Self.restoration(parent: parent, type: type, modalSlot: modalSlot, root: root, schema: schema)
    if let restored = restoration.state {
      _path = Published(initialValue: restored.path)
      _sheet = Published(initialValue: restored.sheet)
      _cover = Published(initialValue: restored.cover)
    }
    super.init(configuration: parent.configuration, root: restoration.state?.root ?? root, parent: parent)
    self.isCompact = isCompact
    parent.addChild(self)
    if let restored = restoration.state {
      restoredModals = [ModalSlot.sheet: restored.sheet, .cover: restored.cover].compactMapValues { $0 }
      restoredPath = restored.path
    }

    restoration.reasons.forEach { log(.error(.restoration($0))) }
    restoration.crash?()
  }

  /// The saved state for the container this router is about to be, with what to report about it.
  private static func restoration(
    parent: BaseRouter,
    type: RouterType,
    modalSlot: ModalSlot?,
    root: AnyRoute,
    schema: RestorationSchema?
  ) -> NavigationRestorationStore.Restoration {
    guard let store = parent.restorationStore else { return .unrestored }
    let path = parent.restorationPath + [restorationSegment(type: type, modalSlot: modalSlot)]
    if type.isPresented {
      // A presented router uses its saved node only when its host restored this very modal in this
      // session. A modal the user presents fresh starts on its default state, and so does everything in it.
      guard let modalSlot, let host = parent as? Router, host.consumeRestoredModal(modalSlot, matching: root) else {
        store.discard(at: path)
        return .unrestored
      }
    } else if !store.allowsSeeding(under: parent) {
      // The screen that builds this container is no longer the one it was saved under.
      store.discard(at: path)
      return .unrestored
    }
    guard let schema else { return .unrestored }
    return store.restore(
      at: path,
      schema: schema,
      crashOnNotCodable: parent.configuration.shouldCrashOnRouteNotFound
    )
  }

  /// Takes the modal this router restored in `slot`, `true` if `route` is the one a child is built for.
  private func consumeRestoredModal(_ slot: ModalSlot, matching route: AnyRoute) -> Bool {
    restoredModalsLock.withLock { restoredModals.removeValue(forKey: slot) } == route
  }

  private func forgetRestoredModal(_ slot: ModalSlot) {
    restoredModalsLock.withLock { _ = restoredModals.removeValue(forKey: slot) }
  }

  /// A dismissing child released without reporting its dismissal ends it, as `dismissingChild` is
  /// weak: the held modal is presented on the main actor, outside the `deinit`.
  override func removeChild(_ child: BaseRouter) {
    super.removeChild(child)
    // `onDisappear` is not enough: a router whose content was built but never shown is released
    // with neither `onDismiss` nor `onDisappear`.
    Task { @MainActor [weak self] in self?.presentPendingModal() }
  }
}

// MARK: - Presentation

extension Router: @preconcurrency PresentationModel {

  @MainActor public func present(_ destination: some Route, withStack: Bool) {
    requestModal(.sheet(AnyRoute(wrapped: destination, inStack: withStack)))
  }

  @MainActor public func cover(_ destination: some Route) {
    requestModal(.cover(AnyRoute(wrapped: destination)))
  }

  @MainActor public func close() {
    guard isPresented else { return }
    pendingModal = nil
    isCloseLoggedExplicitly = true
    triggerClose = true
    log(.action(.close))
  }

  @MainActor public func closeChildren() {
    // A dismissal already in flight stays tracked: a deeplink target requested next must wait for it.
    pendingModal = nil
    let presentedChildren = children.values.compactMap({ $0.value as? Router }).filter(\.isPresented)

    guard !presentedChildren.isEmpty else {
      // A restored modal whose child is not built yet is not on screen to be closed by SwiftUI:
      // a launch deeplink clears it here. A modal that was not restored is left alone.
      let restored = restoredModalsLock.withLock { Set(restoredModals.keys) }
      if restored.contains(.sheet) { sheet = nil }
      if restored.contains(.cover) { cover = nil }
      return
    }
    presentedChildren.forEach {
      $0.isCloseLoggedExplicitly = true
      log(.action(.closeChildren($0)))
    }
    sheet = nil
    cover = nil
  }

  /// Sent by `RoutingView` and `RoutingSplitView` from their sheet and cover `onDismiss`,
  /// so both containers emit ``BaseRouter/dismissed`` the same way.
  ///
  /// Ends the dismissal in flight, then presents the modal requested meanwhile.
  @MainActor func notifyModalDismissed() {
    dismissingChild = nil
    // Observers run with nothing dismissing, so a modal they present is shown right away
    // and, being newer, replaces the held one.
    dismissed.send(self)
    presentPendingModal()
  }

  /// Sent by `RoutingView` when the content of this router leaves the screen. Ends the dismissal of
  /// this router on its parent even if SwiftUI never reports `onDismiss` for it. Observed after
  /// `onDismiss` on iOS, so it changes nothing when `onDismiss` comes.
  @MainActor func notifyContentDisappeared() {
    guard let parent = parent as? Router, parent.dismissingChild === self else { return }
    parent.dismissingChild = nil
    parent.presentPendingModal()
  }

  /// Presents `modal` now, or holds it in place of the held one while a dismissal is in flight.
  @MainActor private func requestModal(_ modal: PendingModal) {
    guard dismissingChild == nil else {
      pendingModal = modal
      return
    }
    pendingModal = nil
    show(modal)
  }

  @MainActor private func presentPendingModal() {
    guard dismissingChild == nil, let modal = pendingModal else { return }
    pendingModal = nil
    show(modal)
  }

  @MainActor private func show(_ modal: PendingModal) {
    switch modal {
    case let .sheet(route):
      log(.navigation(from: currentRoute.wrapped, to: route.wrapped, type: .sheet(withStack: route.inStack)))
      sheet = route
    case let .cover(route):
      log(.navigation(from: currentRoute.wrapped, to: route.wrapped, type: .cover))
      cover = route
    }
  }

  /// Marks the child of a modal leaving its slot as gone, and tracks its dismissal if the slot clears.
  private func modalSlotChanged(from oldValue: AnyRoute?, to newValue: AnyRoute?) {
    guard let oldValue else { return }
    let child = children.values
      .compactMap { $0.value as? Router }
      .filter { $0.isPresented && !$0.hasLeftScreen }
      .presenting([oldValue])
    // No child: SwiftUI never showed this modal, so no `onDismiss` will come, or it showed an
    // error view for a route without destination, a dismissal that cannot be tracked.
    guard let child else { return }
    child.hasLeftScreen = true
    if newValue == nil {
      dismissingChild = child
    }
  }

  /// Catches dismissals that bypass `close()` entirely -- a native swipe-down, tapping outside
  /// the sheet, or a `@Environment(\.dismiss)` call from inside the presented content all clear
  /// `sheet`/`cover` directly through the live `.sheet(item:)`/`.cover(item:)` binding.
  ///
  /// Called on the *parent* (whoever owns `sheet`/`cover`), but attributes the log to the
  /// *presented* child router, matching what `close()` itself logs on. Prefers a child already
  /// flagged `isCloseLoggedExplicitly` -- set by `close()`/`closeChildren()` right before this
  /// fires -- over an arbitrary presented one, so that when both `sheet` and `cover` clear in
  /// the same `closeChildren()` call, each clearing consumes a *different* child's flag instead
  /// of finding the same one twice.
  private func logCloseIfNeeded(from oldValue: AnyRoute?, to newValue: AnyRoute?) {
    guard oldValue != nil, newValue == nil else { return }
    let presentedChildren = children.values.compactMap({ $0.value as? Router }).filter(\.isPresented)
    guard let presentedChild = presentedChildren.first(where: \.isCloseLoggedExplicitly) ?? presentedChildren.first
    else { return }
    guard !presentedChild.isCloseLoggedExplicitly else {
      presentedChild.isCloseLoggedExplicitly = false
      return
    }
    presentedChild.log(.action(.close))
  }
}

// MARK: - Navigation

extension Router: @preconcurrency RouterModel {
  // MARK: Stack
  @MainActor public func route(_ destination: some Route) {
    route(to: destination, type: destination.routingType)
  }

  @MainActor public func update(root destination: some Route) {
    route(to: destination, type: .root)
  }

  @MainActor public func push(_ destination: some Route) {
    route(to: destination, type: .push)
  }

  @MainActor public func popToRoot() {
    guard !path.isEmpty else { return }

    isPathChangeLoggedExplicitly = true
    path.removeAll()
    isPathChangeLoggedExplicitly = false
    log(.action(.popToRoot))
  }

  @MainActor public func pop() {
    guard !path.isEmpty else { return }
    isPathChangeLoggedExplicitly = true
    path.removeLast()
    isPathChangeLoggedExplicitly = false
    log(.action(.pop()))
  }

  @MainActor public func terminate(_ value: some RouteContext) {
    /// Execute all termination observers for the given context type (in both parent and child routers).
    context(value)

    /// Remove all routes above the matched context in the navigation path
    if let context = contexts.first(for: Swift.type(of: value), currentRoute: currentRoute.wrapped) {
      guard path.count - context.pathCount >= 0 else { return }
      let clear = path.count - context.pathCount
      isPathChangeLoggedExplicitly = true
      path.removeLast(clear)
      isPathChangeLoggedExplicitly = false
      log(.action(.pop(count: clear)))
    /// If the context is not found and the router is presented (i.e., displayed modally)
    } else if type.isPresented {
      close()
    /// Otherwise, pops the topmost route from the stack
    } else {
      pop()
    }
  }

  // MARK: Split

  @MainActor public func contentBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    guard self.type.isSplit else { return .constant(nil) }
    return Binding(
      get: { [weak self] in self?.contentSelection as? T },
      set: { [weak self] in self?.select(content: $0) }
    )
  }

  @MainActor public func detailBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    guard self.type.isSplit else { return .constant(nil) }
    return Binding(
      get: { [weak self] in self?.detailSelection as? T },
      set: { [weak self] in self?.select(detail: $0) }
    )
  }

  @MainActor public func select<T: Hashable & Sendable>(content value: T?) {
    guard type.isSplit else { return }

    guard let value else {
      contentSelection = nil
      return
    }
    // Re-selecting the value that's already selected is a no-op -- without this guard,
    // `currentRoute` (evaluated below, before `contentSelection` is updated) already
    // resolves through the *current* selection, so logging would read "navigate from: X
    // to: X" for the same route.
    let newSelection = AnyHashable(value)
    guard newSelection != contentSelection else { return }
    guard let route = contentRouteFactory?(newSelection) else { return }
    log(.navigation(from: currentRoute.wrapped, to: route.wrapped, type: .push))

    contentSelection = newSelection
  }

  @MainActor public func select<T: Hashable & Sendable>(detail value: T?) {
    guard type.isSplit else { return }

    guard let value else {
      detailSelection = nil
      return
    }
    // See the equivalent guard in `select(content:)` -- same "from: X to: X" issue otherwise.
    let newSelection = AnyHashable(value)
    guard newSelection != detailSelection else { return }
    guard let route = detailRouteFactory?(newSelection) else { return }
    log(.navigation(from: currentRoute.wrapped, to: route.wrapped, type: .push))

    detailSelection = newSelection
  }
}

// MARK: - Deeplink

public extension Router {
  /// Handles a deeplink and navigates to the corresponding route.
  ///
  /// This method processes a deeplink by performing the following steps:
  /// 1. Closes all currently presented child routers.
  /// 2. Clears the current navigation path, returning to the root.
  /// 3. Optionally overrides the root route.
  /// 4. Pushes the intermediate routes defined in the deeplink's path.
  /// 5. Navigates to the final destination route with the specified presentation type (if provided).
  ///
  /// - Parameter deeplink: The `DeeplinkRoute` containing the navigation path and optional target route.
  @MainActor func handle(deeplink: DeeplinkRoute<some Route>) {
    // Dismiss all presented child routers
    closeChildren()

    // Clear the current navigation path
    popToRoot()

    // Override the root route
    if let root = deeplink.root {
      route(to: root, type: .root)
    }

    // Add intermediate routes to the navigation path
    for route in deeplink.path {
      push(route)
    }

    // Navigate to the target route with the specified presentation type
    if let targetRoute = deeplink.route {
      route(to: targetRoute, type: deeplink.type)
    }
  }

  /// Handles a deep link into a split-view router's columns.
  ///
  /// This method processes a `SplitDeeplink` by performing the following steps:
  /// 1. Selects `content` (3-column layout only; no-op if this router has no content column).
  /// 2. Selects `detail`.
  /// 3. Applies `deeplink` (if present) within the detail column's own navigation stack.
  ///
  /// No-op if this router was not created as a `.split` router.
  ///
  /// - Parameter splitDeeplink: The `SplitDeeplink` containing the column selections and optional navigation path.
  @MainActor func handle(splitDeeplink: SplitDeeplink<some Hashable & Sendable, some Hashable & Sendable, some Route>) {
    guard type.isSplit else { return }

    if let content = splitDeeplink.content {
      select(content: content)
    }

    if let detail = splitDeeplink.detail {
      select(detail: detail)
    }

    if let deeplink = splitDeeplink.deeplink {
      handle(deeplink: deeplink)
    }
  }
}

// MARK: - Private

private extension Router {

  @MainActor func route(to destination: some Route, type: RoutingType) {
    switch type {
    case .push:
      // Logged by `path`'s `didSet` instead -- see its comment for why.
      path.append(AnyRoute(wrapped: destination))
    case let .sheet(withStack):
      requestModal(.sheet(AnyRoute(wrapped: destination, inStack: withStack)))
    case .cover:
      requestModal(.cover(AnyRoute(wrapped: destination)))
    case .root:
      log(.navigation(from: currentRoute.wrapped, to: destination, type: type))
      root = AnyRoute(wrapped: destination)
    }
  }

  func removeContext(old: [AnyRoute], new: [AnyRoute]) {
    let count = old.count - new.count
    guard count > 0 else { return }

    for element in contexts.all(for: path.suffix(count).map(\.wrapped)) {
      contexts.remove(element)
      log(.context(.remove(element.route, context: element.routerContext)))
    }
  }
}
