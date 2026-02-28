import Testing
@testable import SwiftRouting

struct RouteTests {
  struct IsSameRoute {
    @Test
    func routeTypeAndValueAreSame_isSame_return_true() {
      let expectedRoute = TestRoute.home
      #expect(expectedRoute.isSame(as: TestRoute.home))
    }

    @Test
    func routeTypeDiffers_isSame_return_false() {
      let expectedRoute = DefaultRoute.main
      #expect(expectedRoute.isSame(as: TestRoute.home) == false)
    }
  }
}
