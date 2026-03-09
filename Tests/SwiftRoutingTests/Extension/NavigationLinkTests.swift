import Testing
@testable import SwiftRouting

struct NavigationLinkTests {

  struct AnyRouteWrapping {
    @Test
    func givenRoute_initWithRouteAndLabel_anyRouteWrapsRoute() {
      let expectedRoute = TestRoute.home
      let anyRoute = AnyRoute(wrapped: expectedRoute)

      #expect(anyRoute.wrapped as? TestRoute == expectedRoute)
    }

    @Test
    func givenRoute_initWithLocalizedStringKey_anyRouteWrapsRoute() {
      let expectedRoute = TestRoute.details(id: "42")
      let anyRoute = AnyRoute(wrapped: expectedRoute)

      #expect(anyRoute.wrapped as? TestRoute == expectedRoute)
    }

    @Test
    func givenRoute_initWithString_anyRouteWrapsRoute() {
      let expectedRoute = TestRoute.settings
      let anyRoute = AnyRoute(wrapped: expectedRoute)

      #expect(anyRoute.wrapped as? TestRoute == expectedRoute)
    }

    @Test
    func givenRoute_anyRoute_idMatchesRouteHashValue() {
      let expectedRoute = TestRoute.details(id: "99")
      let anyRoute = AnyRoute(wrapped: expectedRoute)

      #expect(anyRoute.id == expectedRoute.hashValue)
    }

    @Test
    func givenTwoIdenticalRoutes_anyRoute_idsAreEqual() {
      let anyRoute1 = AnyRoute(wrapped: TestRoute.home)
      let anyRoute2 = AnyRoute(wrapped: TestRoute.home)

      #expect(anyRoute1 == anyRoute2)
    }

    @Test
    func givenTwoDifferentRoutes_anyRoute_idsAreNotEqual() {
      let anyRoute1 = AnyRoute(wrapped: TestRoute.home)
      let anyRoute2 = AnyRoute(wrapped: TestRoute.settings)

      #expect(anyRoute1 != anyRoute2)
    }
  }
}
