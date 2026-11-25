@testable import SwiftRouting

enum ModalKind: CaseIterable {
  case sheet
  case cover

  @MainActor
  func request(_ route: TestRoute, on router: Router) {
    switch self {
    case .sheet: router.present(route)
    case .cover: router.cover(route)
    }
  }
}

/// Plays SwiftUI's part around a presenting router.
@MainActor
final class ModalScreen {
  let router: Router
  /// The routers of the modals shown, kept alive like the `@StateObject` of a presented view.
  private var children: [Router] = []

  init(router: Router = Router(configuration: Configuration())) {
    self.router = router
  }

  var sheet: TestRoute? {
    router.sheet?.wrapped as? TestRoute
  }

  var cover: TestRoute? {
    router.cover?.wrapped as? TestRoute
  }

  func modal(_ kind: ModalKind) -> TestRoute? {
    switch kind {
    case .sheet: sheet
    case .cover: cover
    }
  }

  /// Requests `route` and builds its presented router, as SwiftUI does once the modal is shown.
  @discardableResult
  func show(_ route: TestRoute, as kind: ModalKind) -> Router {
    kind.request(route, on: router)
    let child = Router(root: AnyRoute(wrapped: route), type: .presented(route.name), parent: router)
    children.append(child)
    return child
  }

  /// What SwiftUI does to the binding when a modal starts dismissing.
  func startDismissing(_ kind: ModalKind) {
    switch kind {
    case .sheet: router.sheet = nil
    case .cover: router.cover = nil
    }
  }

  /// The presented views are gone and release their routers.
  func releaseChildren() {
    children.removeAll()
  }
}
