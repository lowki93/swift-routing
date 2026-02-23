import Testing
@testable import SwiftRouting

@MainActor
struct BaseRouterTests {
  @MainActor
  struct AddChild: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func childExists_addChild_return_childInChildren() {
      let configuration = Configuration(logger: nil, shouldCrashOnRouteNotFound: false)
      let child = BaseRouter(configuration: configuration)

      #expect(baseRouter.children[child.id] == nil)

      baseRouter.addChild(child)

      #expect(baseRouter.children.count == 1)
      #expect(baseRouter.children[child.id]?.value?.id == child.id)
    }
  }

  @MainActor
  struct RemoveChild: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func childExists_removeChild_return_childRemovedFromChildren() {
      let configuration = Configuration(logger: nil, shouldCrashOnRouteNotFound: false)
      let child = BaseRouter(configuration: configuration)
      baseRouter.addChild(child)
      #expect(baseRouter.children[child.id] != nil)

      baseRouter.removeChild(child)

      #expect(baseRouter.children[child.id] == nil)
      #expect(baseRouter.children.isEmpty)
    }

    @Test
    func childDoesNotExist_removeChild_return_noChange() {
      let configuration = Configuration(logger: nil, shouldCrashOnRouteNotFound: false)
      let child = BaseRouter(configuration: configuration)
      #expect(baseRouter.children.isEmpty)

      baseRouter.removeChild(child)

      #expect(baseRouter.children.isEmpty)
    }
  }

  @MainActor
  struct ClearChildren: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func childrenExist_clearChildren_return_emptyChildren() {
      let configuration = Configuration(logger: nil, shouldCrashOnRouteNotFound: false)
      let firstChild = BaseRouter(configuration: configuration)
      let secondChild = BaseRouter(configuration: configuration)
      baseRouter.addChild(firstChild)
      baseRouter.addChild(secondChild)
      #expect(baseRouter.children.count == 2)

      baseRouter.clearChildren()

      #expect(baseRouter.children.isEmpty)
    }
  }

  @MainActor
  struct Log {
    @Test
    func messageDelete_log_return_loggerCalledWithDelete() {
      let setup = makeBaseRouterWithLoggerSpy()
      let baseRouter = setup.baseRouter

      baseRouter.log(.delete)

      #expect(setup.received()?.router.id == baseRouter.id)
      assertLogMessageKind(setup.received()?.message, is: .delete)
    }

    @Test
    func messageActionClose_log_return_loggerCalledWithActionClose() {
      let setup = makeBaseRouterWithLoggerSpy()
      let baseRouter = setup.baseRouter

      baseRouter.log(.action(.close))

      #expect(setup.received()?.router.id == baseRouter.id)
      assertLogMessageKind(setup.received()?.message, is: .actionClose)
    }

    @Test
    func messageOnAppear_log_return_loggerCalledWithOnAppearRoute() {
      let setup = makeBaseRouterWithLoggerSpy()
      let baseRouter = setup.baseRouter

      baseRouter.log(.onAppear(TestRoute.home))

      #expect(setup.received()?.router.id == baseRouter.id)
      assertLogMessageKind(setup.received()?.message, is: .onAppear(.home))
    }
  }

  @MainActor
  struct FindTab: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func matchingTabExists_findTab_return_routerForTab() {
      let routerInTab = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .tab("home", hideTabBarOnPush: false),
        parent: baseRouter
      )

      let foundRouter = baseRouter.find(tab: TestTabRoute.home)

      #expect(foundRouter?.id == routerInTab.id)
    }

    @Test
    func matchingTabDoesNotExist_findTab_return_nil() {
      let foundRouter = baseRouter.find(tab: TestTabRoute.settings)
      #expect(foundRouter == nil)
    }
  }

  @MainActor
  struct TabRouterLookup: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func noTabRouter_tabRouter_return_nil() {
      #expect(baseRouter.tabRouter == nil)
    }

    @Test
    func oneTabRouter_tabRouter_return_instance() {
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: baseRouter)

      #expect(baseRouter.tabRouter?.id == tabRouter.id)
    }

    @Test
    func multipleTabRouters_tabRouter_return_nil() {
      _ = TabRouter(tab: TestTabRoute.home, parent: baseRouter)
      _ = TabRouter(tab: OtherTestTabRoute.main, parent: baseRouter)

      #expect(baseRouter.tabRouter == nil)
    }
  }

  @MainActor
  struct TabRouterForTabRoute: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func noTabRouter_tabRouterFor_return_nil() {
      let foundTabRouter = baseRouter.tabRouter(for: TestTabRoute.home)
      #expect(foundTabRouter == nil)
    }

    @Test
    func matchingTabRouteTypeExists_tabRouterFor_return_tabRouter() {
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: baseRouter)

      let foundTabRouter = baseRouter.tabRouter(for: TestTabRoute.settings)

      #expect(foundTabRouter?.id == tabRouter.id)
    }

    @Test
    func matchingTabRouteTypeDoesNotExist_tabRouterFor_return_nil() {
      _ = TabRouter(tab: OtherTestTabRoute.main, parent: baseRouter)

      let foundTabRouter = baseRouter.tabRouter(for: TestTabRoute.home)

      #expect(foundTabRouter == nil)
    }
  }

  @MainActor
  struct FindRouterInTabRouter: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func noTabRouter_findRouterInTabRouter_return_nil() {
      let foundRouter = baseRouter.findRouterInTabRouter(for: TestTabRoute.home)
      #expect(foundRouter == nil)
    }

    @Test
    func tabRouterExistsWithoutMatchingRouter_findRouterInTabRouter_return_nil() {
      _ = TabRouter(tab: TestTabRoute.home, parent: baseRouter)

      let foundRouter = baseRouter.findRouterInTabRouter(for: TestTabRoute.home)

      #expect(foundRouter == nil)
    }

    @Test
    func matchingTabRouterAndRouterExist_findRouterInTabRouter_return_router() {
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: baseRouter)
      let routerInTab = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .tab("home", hideTabBarOnPush: false),
        parent: tabRouter
      )

      let foundRouter = baseRouter.findRouterInTabRouter(for: TestTabRoute.home)

      #expect(foundRouter?.id == routerInTab.id)
    }
  }
}

@MainActor
private func makeBaseRouterWithLoggerSpy() -> (
  baseRouter: BaseRouter,
  received: () -> LoggerConfiguration?
) {
  var received: LoggerConfiguration?
  let configuration = Configuration(
    logger: { loggerConfiguration in
      received = loggerConfiguration
    },
    shouldCrashOnRouteNotFound: false
  )

  return (
    baseRouter: BaseRouter(configuration: configuration),
    received: { received }
  )
}
