import Testing
@testable import SwiftRouting

@MainActor
struct DeeplinkRouteTests {

  @MainActor
  struct PopToRootFactory {
    @Test
    func noParameters_popToRoot_return_nilRouteAndNilRoot() {
      let deeplink = DeeplinkRoute<TestRoute>.popToRoot()

      #expect(deeplink.route == nil)
      #expect(deeplink.root == nil)
      #expect(deeplink.path.isEmpty)
    }

    @Test
    func withRoot_popToRoot_return_nilRouteAndProvidedRoot() {
      let deeplink = DeeplinkRoute<TestRoute>.popToRoot(root: .home)

      #expect(deeplink.route == nil)
      #expect(deeplink.root == .home)
      #expect(deeplink.path.isEmpty)
    }
  }

  @MainActor
  struct PushFactory {
    @Test
    func routeOnly_push_return_pushTypeAndRoute() {
      let deeplink = DeeplinkRoute.push(TestRoute.details(id: "42"))

      #expect(deeplink.route == .details(id: "42"))
      #expect(deeplink.root == nil)
      #expect(deeplink.path.isEmpty)
      let expectedIsPush: Bool
      if case .push = deeplink.type {
        expectedIsPush = true
      } else {
        expectedIsPush = false
      }
      #expect(expectedIsPush)
    }

    @Test
    func withRootAndPath_push_return_allPropertiesSet() {
      let deeplink = DeeplinkRoute.push(
        TestRoute.details(id: "final"),
        root: .home,
        path: [.settings]
      )

      #expect(deeplink.route == .details(id: "final"))
      #expect(deeplink.root == .home)
      #expect(deeplink.path.count == 1)
      #expect(deeplink.path.first == .settings)
    }
  }

  @MainActor
  struct PresentFactory {
    @Test
    func routeOnly_present_return_sheetTypeWithStackTrue() {
      let deeplink = DeeplinkRoute.present(TestRoute.settings)

      #expect(deeplink.route == .settings)
      let expectedIsSheetWithStack: Bool
      if case .sheet(withStack: true) = deeplink.type {
        expectedIsSheetWithStack = true
      } else {
        expectedIsSheetWithStack = false
      }
      #expect(expectedIsSheetWithStack)
    }

    @Test
    func withStackFalse_present_return_sheetTypeWithStackFalse() {
      let deeplink = DeeplinkRoute.present(TestRoute.settings, withStack: false)

      let expectedIsSheetWithoutStack: Bool
      if case .sheet(withStack: false) = deeplink.type {
        expectedIsSheetWithoutStack = true
      } else {
        expectedIsSheetWithoutStack = false
      }
      #expect(expectedIsSheetWithoutStack)
    }

    @Test
    func withRootAndPath_present_return_allPropertiesSet() {
      let deeplink = DeeplinkRoute.present(
        TestRoute.details(id: "sheet"),
        root: .home,
        path: [.settings]
      )

      #expect(deeplink.route == .details(id: "sheet"))
      #expect(deeplink.root == .home)
      #expect(deeplink.path.count == 1)
    }
  }

  @MainActor
  struct CoverFactory {
    @Test
    func routeOnly_cover_return_coverType() {
      let deeplink = DeeplinkRoute.cover(TestRoute.settings)

      #expect(deeplink.route == .settings)
      let expectedIsCover: Bool
      if case .cover = deeplink.type {
        expectedIsCover = true
      } else {
        expectedIsCover = false
      }
      #expect(expectedIsCover)
    }

    @Test
    func withRootAndPath_cover_return_allPropertiesSet() {
      let deeplink = DeeplinkRoute.cover(
        TestRoute.details(id: "cover"),
        root: .home,
        path: [.settings]
      )

      #expect(deeplink.route == .details(id: "cover"))
      #expect(deeplink.root == .home)
      #expect(deeplink.path.count == 1)
    }
  }

  @MainActor
  struct UpdateRootFactory {
    @Test
    func route_updateRoot_return_rootTypeAndRouteAsRoot() {
      let deeplink = DeeplinkRoute.updateRoot(TestRoute.home)

      #expect(deeplink.route == nil)
      #expect(deeplink.root == .home)
      #expect(deeplink.path.isEmpty)
      let expectedIsRoot: Bool
      if case .root = deeplink.type {
        expectedIsRoot = true
      } else {
        expectedIsRoot = false
      }
      #expect(expectedIsRoot)
    }
  }

  @MainActor
  struct HandleDeeplinkIntegration: RouterTestSuite {
    let router: Router

    @Test
    func popToRootDeeplink_handle_return_pathClearedAndNoNavigation() {
      router.push(TestRoute.home)
      router.push(TestRoute.settings)
      #expect(router.path.count == 2)
      let deeplink = DeeplinkRoute<TestRoute>.popToRoot()

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
    }

    @Test
    func popToRootWithNewRoot_handle_return_pathClearedAndRootUpdated() {
      router.push(TestRoute.home)
      router.push(TestRoute.settings)
      #expect(router.path.count == 2)
      let deeplink = DeeplinkRoute<TestRoute>.popToRoot(root: .home)

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.root.wrapped as? TestRoute) == .home)
      #expect((router.currentRoute.wrapped as? TestRoute) == .home)
    }

    @Test
    func pushDeeplink_handle_return_routePushed() {
      let deeplink = DeeplinkRoute.push(TestRoute.details(id: "pushed"))

      router.handle(deeplink: deeplink)

      #expect(router.path.count == 1)
      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "pushed"))
    }

    @Test
    func presentDeeplink_handle_return_sheetPresented() {
      let deeplink = DeeplinkRoute.present(TestRoute.settings)

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.sheet?.wrapped as? TestRoute) == .settings)
    }

    @Test
    func coverDeeplink_handle_return_coverPresented() {
      let deeplink = DeeplinkRoute.cover(TestRoute.settings)

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.cover?.wrapped as? TestRoute) == .settings)
    }

    @Test
    func updateRootDeeplink_handle_return_rootUpdated() {
      let deeplink = DeeplinkRoute.updateRoot(TestRoute.home)

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.root.wrapped as? TestRoute) == .home)
      #expect((router.currentRoute.wrapped as? TestRoute) == .home)
    }
  }
}
