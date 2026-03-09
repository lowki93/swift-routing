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

struct ShouldCrashOnRouteNotFound {
  @Test
  func whenSetToFalse_triggerCrashIfNeeded_doesNotCallCrashHandler() {
    var crashed = false

    ErrorView<TestRouteDestination, EmptyView>.triggerCrashIfNeeded(
      message: "route not found",
      shouldCrash: false,
      crashHandler: { _ in crashed = true }
    )

    #expect(crashed == false)
  }

  @Test
  func whenSetToTrue_triggerCrashIfNeeded_callsCrashHandler() {
    var crashedMessage: String?

    ErrorView<TestRouteDestination, EmptyView>.triggerCrashIfNeeded(
      message: "route not found",
      shouldCrash: true,
      crashHandler: { crashedMessage = $0 }
    )

    #expect(crashedMessage == "route not found")
  }
}
