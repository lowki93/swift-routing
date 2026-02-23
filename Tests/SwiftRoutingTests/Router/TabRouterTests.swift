import Testing
@testable import SwiftRouting

@MainActor
struct TabRouterTests {
  @MainActor
  struct Init {
    @Test
    func tabAndParentAreSet_init_return_tabRouterAttachedToParent() {
      let parentRouter = Router(
        configuration: Configuration(logger: nil, shouldCrashOnRouteNotFound: false)
      )

      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .home)
      #expect(parentRouter.children[tabRouter.id]?.value?.id == tabRouter.id)
    }

    @Test
    func sameTabTypeAlreadyExists_init_return_previousTabRouterReplaced() {
      let parentRouter = Router(
        configuration: Configuration(logger: nil, shouldCrashOnRouteNotFound: false)
      )
      let first = TabRouter(tab: TestTabRoute.home, parent: parentRouter)

      let second = TabRouter(tab: TestTabRoute.settings, parent: parentRouter)

      #expect(parentRouter.children[first.id] == nil)
      #expect(parentRouter.children[second.id]?.value?.id == second.id)
      #expect(parentRouter.children.count == 1)
    }
  }

  @MainActor
  struct Routers: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func noChildRouter_routers_return_emptyArray() {
      #expect(tabRouter.routers.isEmpty)
    }

    @Test
    func childRoutersExist_routers_return_allChildRouters() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      #expect(tabRouter.routers.count == 2)
      #expect(tabRouter.routers.contains(where: { $0.id == homeRouter.id }))
      #expect(tabRouter.routers.contains(where: { $0.id == settingsRouter.id }))
    }
  }

  @MainActor
  struct ChangeTab: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func tabExists_changeTab_return_updatedCurrentTab() {
      tabRouter.change(tab: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
    }
  }

  @MainActor
  struct PushRoute: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_pushInTab_return_routeInTargetRouterPath() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.push(TestRoute.details(id: "42"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(homeRouter.path.isEmpty)
      #expect((settingsRouter.path.last?.wrapped as? TestRoute) == .details(id: "42"))
    }

    @Test
    func tabIsNil_pushInTab_return_routeInCurrentTabRouterPath() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.push(TestRoute.details(id: "nil-tab"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(homeRouter.path.isEmpty)
      #expect((settingsRouter.path.last?.wrapped as? TestRoute) == .details(id: "nil-tab"))
    }
  }

  @MainActor
  struct UpdateRoot: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_updateRootInTab_return_updatedRootInTargetRouter() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.update(root: TestRoute.details(id: "new-root"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect((homeRouter.root.wrapped as? TestRoute) == .home)
      #expect((settingsRouter.root.wrapped as? TestRoute) == .details(id: "new-root"))
    }

    @Test
    func tabIsNil_updateRootInTab_return_updatedRootInCurrentTabRouter() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.update(root: TestRoute.details(id: "current-tab-root"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect((homeRouter.root.wrapped as? TestRoute) == .home)
      #expect((settingsRouter.root.wrapped as? TestRoute) == .details(id: "current-tab-root"))
    }
  }

  @MainActor
  struct PresentRoute: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_presentInTab_return_sheetInTargetRouter() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.present(TestRoute.details(id: "sheet"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(homeRouter.sheet == nil)
      #expect((settingsRouter.sheet?.wrapped as? TestRoute) == .details(id: "sheet"))
    }

    @Test
    func tabIsNil_presentInTab_return_sheetInCurrentTabRouter() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.present(TestRoute.details(id: "nil-tab-sheet"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(homeRouter.sheet == nil)
      #expect((settingsRouter.sheet?.wrapped as? TestRoute) == .details(id: "nil-tab-sheet"))
    }
  }

  @MainActor
  struct CoverRoute: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_coverInTab_return_coverInTargetRouter() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.cover(TestRoute.details(id: "cover"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(homeRouter.cover == nil)
      #expect((settingsRouter.cover?.wrapped as? TestRoute) == .details(id: "cover"))
    }

    @Test
    func tabIsNil_coverInTab_return_coverInCurrentTabRouter() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.cover(TestRoute.details(id: "nil-tab-cover"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(homeRouter.cover == nil)
      #expect((settingsRouter.cover?.wrapped as? TestRoute) == .details(id: "nil-tab-cover"))
    }
  }

  @MainActor
  struct PopToRoot: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func pathHasElements_popToRootInTab_return_emptyPathInTargetRouter() {
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      settingsRouter.push(TestRoute.home)
      settingsRouter.push(TestRoute.details(id: "42"))
      #expect(settingsRouter.path.count == 2)

      tabRouter.popToRoot(in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .home)
      #expect(settingsRouter.path.isEmpty)
    }

    @Test
    func tabIsNil_popToRootInTab_return_emptyPathInCurrentTabRouter() {
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      settingsRouter.push(TestRoute.home)
      settingsRouter.push(TestRoute.details(id: "42"))
      #expect(settingsRouter.path.count == 2)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.popToRoot(in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(homeRouter.path.isEmpty)
      #expect(settingsRouter.path.isEmpty)
    }
  }
}

@MainActor
private func attachRouter(
  in tabRouter: TabRouter,
  tab: TestTabRoute,
  root: TestRoute
) -> Router {
  Router(
    root: AnyRoute(wrapped: root),
    type: tab.type,
    parent: tabRouter
  )
}
