import Testing
import SwiftUI
@testable import SwiftRouting

@MainActor
struct ErrorViewTests {

  struct Error {
    @Test
    func routeNotFound_description_containsRouteTypeName() {
      let error = RouterError.routeNotFound(route: AnyRoute(wrapped: DefaultRoute.main), in: "TestRouteDestination")

      #expect(error.description.contains("DefaultRoute"))
    }

    @Test
    func routeNotFound_description_containsDestinationName() {
      let error = RouterError.routeNotFound(route: AnyRoute(wrapped: DefaultRoute.main), in: "TestRouteDestination")

      #expect(error.description.contains("TestRouteDestination"))
    }
  }
}
