import Testing
import SwiftUI
@testable import SwiftRouting

@MainActor
struct ErrorViewTests {

  struct Message {
    @MainActor @Test
    func unmatchedRoute_message_containsRouteTypeName() {
      let route = AnyRoute(wrapped: DefaultRoute.main)
      let view = ErrorView(route: route, destination: TestRouteDestination.self) { _, _ in EmptyView() }

      #expect(view.message.contains("DefaultRoute"))
    }

    @MainActor @Test
    func unmatchedRoute_message_containsDestinationTypeName() {
      let route = AnyRoute(wrapped: DefaultRoute.main)
      let view = ErrorView(route: route, destination: TestRouteDestination.self) { _, _ in EmptyView() }

      #expect(view.message.contains("TestRouteDestination"))
    }
  }
}
