import Testing
@testable import SwiftRouting

struct RouterErrorTests {

  struct RouteNotFound {
    @Test
    func routeNotFound_description_containsRouteTypeName() {
      let error = RouterError.routeNotFound(route: DefaultRoute.main, in: TestRouteDestination.self)

      #expect(error.description.contains("DefaultRoute"))
    }

    @Test
    func routeNotFound_description_containsDestinationName() {
      let error = RouterError.routeNotFound(route: DefaultRoute.main, in: TestRouteDestination.self)

      #expect(error.description.contains("TestRouteDestination"))
    }
  }

  struct Restoration {
    @Test
    func notCodable_description_containsContainerAndType() {
      let error = RouterError.restoration(.notCodable(container: "app/stack(home)", type: "TestRoute"))

      #expect(error.description.contains("app/stack(home)"))
      #expect(error.description.contains("TestRoute"))
    }

    @Test
    func decodingFailed_description_containsContainerAndUnderlyingError() {
      let error = RouterError.restoration(.decodingFailed(container: "app/stack(home)", error: "missing key"))

      #expect(error.description.contains("app/stack(home)"))
      #expect(error.description.contains("missing key"))
    }

    @Test
    func encodingFailed_description_containsContainerAndUnderlyingError() {
      let error = RouterError.restoration(.encodingFailed(container: "app/stack(home)", error: "bad value"))

      #expect(error.description.contains("app/stack(home)"))
      #expect(error.description.contains("bad value"))
    }

    @Test
    func duplicateKey_description_containsContainer() {
      let error = RouterError.restoration(.duplicateKey(container: "app/stack(home)"))

      #expect(error.description.contains("app/stack(home)"))
    }
  }
}
