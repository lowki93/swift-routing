import Testing
import SwiftRouting
@testable import SwiftRoutingTestSupport

private enum FixtureTab: TabRoute {
  case home
  case profile

  var name: String {
    switch self {
    case .home: "home"
    case .profile: "profile"
    }
  }
}

@MainActor
struct TabRouterSpyTests {
  struct ChangeTab {
    @Test
    func changeTab_return_recordedTab() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      spy.change(tab: FixtureTab.profile)

      #expect((spy.changedTabs.first as? FixtureTab) == .profile)
    }
  }

  struct PushRoute {
    @Test
    func pushWithTab_return_recordedRouteAndTab() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      spy.push(FixtureRoute.details(id: "42"), in: FixtureTab.profile)

      #expect((spy.pushedRoutes.first?.route as? FixtureRoute) == .details(id: "42"))
      #expect((spy.pushedRoutes.first?.tab as? FixtureTab) == .profile)
    }

    @Test
    func pushWithoutTab_return_recordedRouteWithNilTab() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      spy.push(FixtureRoute.details(id: "42"))

      #expect((spy.pushedRoutes.first?.route as? FixtureRoute) == .details(id: "42"))
      #expect(spy.pushedRoutes.first?.tab == nil)
    }
  }

  struct PresentRoute {
    @Test
    func present_return_recordedRouteAndTab() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      spy.present(FixtureRoute.details(id: "sheet"), in: FixtureTab.profile)

      #expect((spy.presentedRoutes.first?.route as? FixtureRoute) == .details(id: "sheet"))
      #expect((spy.presentedRoutes.first?.tab as? FixtureTab) == .profile)
    }
  }

  struct CoverRoute {
    @Test
    func cover_return_recordedRouteAndTab() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      spy.cover(FixtureRoute.details(id: "cover"), in: FixtureTab.profile)

      #expect((spy.coveredRoutes.first?.route as? FixtureRoute) == .details(id: "cover"))
      #expect((spy.coveredRoutes.first?.tab as? FixtureTab) == .profile)
    }
  }

  struct UpdateRoot {
    @Test
    func updateRoot_return_recordedRouteAndTab() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      spy.update(root: FixtureRoute.details(id: "new-root"), in: FixtureTab.profile)

      #expect((spy.updatedRoots.first?.route as? FixtureRoute) == .details(id: "new-root"))
      #expect((spy.updatedRoots.first?.tab as? FixtureTab) == .profile)
    }
  }

  struct PopToRoot {
    @Test
    func popToRoot_return_recordedTab() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      spy.popToRoot(in: FixtureTab.profile)

      #expect((spy.popToRootTabs.first.flatMap { $0 } as? FixtureTab) == .profile)
    }
  }

  @MainActor
  struct Unsupported {
    @Test
    func hierarchyLookups_return_nilOrNoOp() {
      let spy = TabRouterSpy(root: FixtureRoute.home)

      #expect(spy.tabRouter == nil)
      #expect(spy.deepestRouter() == nil)
      spy.clearChildren()
    }
  }
}
