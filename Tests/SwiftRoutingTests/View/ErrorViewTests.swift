import Testing
import SwiftUI
@testable import SwiftRouting

@MainActor
struct ErrorViewTests {

  // ErrorView.message uses `route` and `destination` only — no router environment needed.
  // shouldCrashOnRouteNotFound = true triggers fatalError, which cannot be unit tested.

  struct Message {
    @Test
    func unmatchedRoute_message_containsRouteTypeName() {
      let route = AnyRoute(wrapped: DefaultRoute.main)
      let view = ErrorView(route: route, destination: TestRouteDestination.self) { _, _ in EmptyView() }

      #expect(view.message.contains("DefaultRoute"))
    }

    @Test
    func unmatchedRoute_message_containsDestinationTypeName() {
      let route = AnyRoute(wrapped: DefaultRoute.main)
      let view = ErrorView(route: route, destination: TestRouteDestination.self) { _, _ in EmptyView() }

      #expect(view.message.contains("TestRouteDestination"))
    }
  }

  struct ShouldCrashOnRouteNotFound {
    @Test
    func whenSetToFalse_configuration_crashIsDisabled() {
      let configuration = Configuration(logger: nil, shouldCrashOnRouteNotFound: false)

      #expect(configuration.shouldCrashOnRouteNotFound == false)
    }

    @Test
    func whenSetToTrue_configuration_crashIsEnabled() {
      let configuration = Configuration(logger: nil, shouldCrashOnRouteNotFound: true)

      #expect(configuration.shouldCrashOnRouteNotFound == true)
    }
  }
}
