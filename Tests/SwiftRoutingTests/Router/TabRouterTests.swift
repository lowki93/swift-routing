import Testing
@testable import SwiftRouting

@MainActor
struct TabRouterTests {
  @MainActor
  struct Init {
    @Test
    func tabAndParentAreSet_init_return_tabRouterAttachedToParent() {
      let parentRouter = Router(
        configuration: Configuration()
      )

      let expectedTabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)

      #expect((expectedTabRouter.tab.wrapped as? TestTabRoute) == .home)
      #expect(parentRouter.children[expectedTabRouter.id]?.value?.id == expectedTabRouter.id)
    }

    @Test
    func sameTabTypeAlreadyExists_init_return_previousTabRouterReplaced() {
      let parentRouter = Router(
        configuration: Configuration()
      )
      let expectedFirstTabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)

      let expectedSecondTabRouter = TabRouter(tab: TestTabRoute.settings, parent: parentRouter)

      #expect(parentRouter.children[expectedFirstTabRouter.id] == nil)
      #expect(parentRouter.children[expectedSecondTabRouter.id]?.value?.id == expectedSecondTabRouter.id)
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
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      #expect(tabRouter.routers.count == 2)
      #expect(tabRouter.routers.contains(where: { $0.id == expectedHomeRouter.id }))
      #expect(tabRouter.routers.contains(where: { $0.id == expectedSettingsRouter.id }))
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

    @Test
    func tabExists_changeTab_return_loggerCalledWithChangeTab() {
      let loggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedParentRouter = Router(configuration: Configuration(loggerSpy: loggerSpy))
      let expectedTabRouter = TabRouter(tab: TestTabRoute.home, parent: expectedParentRouter)

      expectedTabRouter.change(tab: TestTabRoute.settings)

      #expect((expectedTabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(loggerSpy.receivedRouterId == expectedTabRouter.id)
      assertLogMessageKind(loggerSpy, is: .action(.changeTab(TestTabRoute.settings)))
    }
  }

  @MainActor
  struct PushRoute: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_pushInTab_return_routeInTargetRouterPath() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.push(TestRoute.details(id: "42"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.path.isEmpty)
      #expect((expectedSettingsRouter.path.last?.wrapped as? TestRoute) == .details(id: "42"))
    }

    @Test
    func tabIsNil_pushInTab_return_routeInCurrentTabRouterPath() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.push(TestRoute.details(id: "nil-tab"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.path.isEmpty)
      #expect((expectedSettingsRouter.path.last?.wrapped as? TestRoute) == .details(id: "nil-tab"))
    }
  }

  @MainActor
  struct UpdateRoot: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_updateRootInTab_return_updatedRootInTargetRouter() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.update(root: TestRoute.details(id: "new-root"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect((expectedHomeRouter.root.wrapped as? TestRoute) == .home)
      #expect((expectedSettingsRouter.root.wrapped as? TestRoute) == .details(id: "new-root"))
    }

    @Test
    func tabIsNil_updateRootInTab_return_updatedRootInCurrentTabRouter() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.update(root: TestRoute.details(id: "current-tab-root"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect((expectedHomeRouter.root.wrapped as? TestRoute) == .home)
      #expect((expectedSettingsRouter.root.wrapped as? TestRoute) == .details(id: "current-tab-root"))
    }
  }

  @MainActor
  struct PresentRoute: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_presentInTab_return_sheetInTargetRouter() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.present(TestRoute.details(id: "sheet"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.sheet == nil)
      #expect((expectedSettingsRouter.sheet?.wrapped as? TestRoute) == .details(id: "sheet"))
    }

    @Test
    func tabIsNil_presentInTab_return_sheetInCurrentTabRouter() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.present(TestRoute.details(id: "nil-tab-sheet"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.sheet == nil)
      #expect((expectedSettingsRouter.sheet?.wrapped as? TestRoute) == .details(id: "nil-tab-sheet"))
    }
  }

  @MainActor
  struct CoverRoute: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func matchingTabRouterExists_coverInTab_return_coverInTargetRouter() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)

      tabRouter.cover(TestRoute.details(id: "cover"), in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.cover == nil)
      #expect((expectedSettingsRouter.cover?.wrapped as? TestRoute) == .details(id: "cover"))
    }

    @Test
    func tabIsNil_coverInTab_return_coverInCurrentTabRouter() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.cover(TestRoute.details(id: "nil-tab-cover"), in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.cover == nil)
      #expect((expectedSettingsRouter.cover?.wrapped as? TestRoute) == .details(id: "nil-tab-cover"))
    }
  }

  @MainActor
  struct PopToRoot: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func pathHasElements_popToRootInTab_return_emptyPathInTargetRouter() {
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      expectedSettingsRouter.push(TestRoute.home)
      expectedSettingsRouter.push(TestRoute.details(id: "42"))
      #expect(expectedSettingsRouter.path.count == 2)

      tabRouter.popToRoot(in: TestTabRoute.settings)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .home)
      #expect(expectedSettingsRouter.path.isEmpty)
    }

    @Test
    func tabIsNil_popToRootInTab_return_emptyPathInCurrentTabRouter() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      expectedSettingsRouter.push(TestRoute.home)
      expectedSettingsRouter.push(TestRoute.details(id: "42"))
      #expect(expectedSettingsRouter.path.count == 2)
      tabRouter.change(tab: TestTabRoute.settings)

      tabRouter.popToRoot(in: nil)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.path.isEmpty)
      #expect(expectedSettingsRouter.path.isEmpty)
    }
  }

  @MainActor
  struct HandleTabDeeplink: TabRouterTestSuite {
    let parentRouter: Router
    let tabRouter: TabRouter

    @Test
    func deeplinkIsNil_handleTabDeeplink_return_tabChangedOnly() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      expectedHomeRouter.push(TestRoute.details(id: "existing"))
      let tabDeeplink = TabDeeplink<TestTabRoute, TestRoute>(tab: .settings, deeplink: nil)

      tabRouter.handle(tabDeeplink: tabDeeplink)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.path.count == 1)
      #expect(expectedSettingsRouter.path.isEmpty)
    }

    @Test
    func deeplinkWithPushType_handleTabDeeplink_return_routePushedInTargetTab() {
      let expectedHomeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      let deeplink = DeeplinkRoute(type: .push, route: TestRoute.details(id: "deeplink"))
      let tabDeeplink = TabDeeplink(tab: TestTabRoute.settings, deeplink: deeplink)

      tabRouter.handle(tabDeeplink: tabDeeplink)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedHomeRouter.path.isEmpty)
      #expect((expectedSettingsRouter.path.last?.wrapped as? TestRoute) == .details(id: "deeplink"))
    }

    @Test
    func deeplinkWithPath_handleTabDeeplink_return_pathAndRouteInTargetTab() {
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      let deeplink = DeeplinkRoute(
        type: .push,
        route: TestRoute.details(id: "final"),
        path: [TestRoute.home, TestRoute.settings]
      )
      let tabDeeplink = TabDeeplink(tab: TestTabRoute.settings, deeplink: deeplink)

      tabRouter.handle(tabDeeplink: tabDeeplink)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedSettingsRouter.path.count == 3)
      #expect((expectedSettingsRouter.path[0].wrapped as? TestRoute) == .home)
      #expect((expectedSettingsRouter.path[1].wrapped as? TestRoute) == .settings)
      #expect((expectedSettingsRouter.path[2].wrapped as? TestRoute) == .details(id: "final"))
    }

    @Test
    func deeplinkWithRoot_handleTabDeeplink_return_rootUpdatedInTargetTab() {
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      let deeplink = DeeplinkRoute(
        root: TestRoute.home,
        type: .push,
        route: TestRoute.details(id: "after-root")
      )
      let tabDeeplink = TabDeeplink(tab: TestTabRoute.settings, deeplink: deeplink)

      tabRouter.handle(tabDeeplink: tabDeeplink)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect((expectedSettingsRouter.root.wrapped as? TestRoute) == .home)
      #expect((expectedSettingsRouter.path.last?.wrapped as? TestRoute) == .details(id: "after-root"))
    }

    @Test
    func deeplinkWithSheetType_handleTabDeeplink_return_sheetPresentedInTargetTab() {
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      let deeplink = DeeplinkRoute(type: .sheet(withStack: true), route: TestRoute.details(id: "sheet"))
      let tabDeeplink = TabDeeplink(tab: TestTabRoute.settings, deeplink: deeplink)

      tabRouter.handle(tabDeeplink: tabDeeplink)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedSettingsRouter.path.isEmpty)
      #expect((expectedSettingsRouter.sheet?.wrapped as? TestRoute) == .details(id: "sheet"))
    }

    @Test
    func existingPathInTargetTab_handleTabDeeplink_return_pathClearedAndDeeplinkApplied() {
      let expectedSettingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      expectedSettingsRouter.push(TestRoute.home)
      expectedSettingsRouter.push(TestRoute.details(id: "existing"))
      #expect(expectedSettingsRouter.path.count == 2)
      let deeplink = DeeplinkRoute(type: .push, route: TestRoute.details(id: "new"))
      let tabDeeplink = TabDeeplink(tab: TestTabRoute.settings, deeplink: deeplink)

      tabRouter.handle(tabDeeplink: tabDeeplink)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(expectedSettingsRouter.path.count == 1)
      #expect((expectedSettingsRouter.path.last?.wrapped as? TestRoute) == .details(id: "new"))
    }

    @Test
    func tabRouterDoesNotExistForTab_handleTabDeeplink_return_tabChangedOnly() {
      let tabDeeplink = TabDeeplink(
        tab: TestTabRoute.settings,
        deeplink: DeeplinkRoute(type: .push, route: TestRoute.details(id: "orphan"))
      )

      tabRouter.handle(tabDeeplink: tabDeeplink)

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
      #expect(tabRouter.routers.isEmpty)
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
