import Testing
@testable import SwiftRouting

struct RouterErrorTests {

  struct RouteNotFound {
    @Test
    func routeNotFound_description_containsRouteTypeName() {
      let error = RouterError.routeNotFound(route: DefaultRoute.main, in: "TestRouteDestination")

      #expect(error.description.contains("DefaultRoute"))
    }

    @Test
    func routeNotFound_description_containsDestinationName() {
      let error = RouterError.routeNotFound(route: DefaultRoute.main, in: "TestRouteDestination")

      #expect(error.description.contains("TestRouteDestination"))
    }
  }
}
