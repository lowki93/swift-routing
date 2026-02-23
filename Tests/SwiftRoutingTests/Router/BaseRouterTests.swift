import Testing
import Foundation
@testable import SwiftRouting

@MainActor
struct BaseRouterTests {
  @MainActor
  struct Deinit {
    @Test
    func baseRouterIsDeallocated_deinit_return_loggerCalledWithDelete() {
      let loggerSpy = LoggerSpy(storesConfiguration: false)
      var expectedBaseRouter: BaseRouter? = BaseRouter(configuration: Configuration(loggerSpy: loggerSpy))
      let expectedBaseRouterId = expectedBaseRouter?.id

      expectedBaseRouter = nil

      #expect(expectedBaseRouter == nil)
      #expect(loggerSpy.receivedRouterId == expectedBaseRouterId)
      assertLogMessageKind(loggerSpy, is: .delete)
    }
  }

  @MainActor
  struct AddChild: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func childExists_addChild_return_childInChildren() {
      let configuration = Configuration()
      let expectedChild = BaseRouter(configuration: configuration)

      #expect(baseRouter.children[expectedChild.id] == nil)

      baseRouter.addChild(expectedChild)

      #expect(baseRouter.children.count == 1)
      #expect(baseRouter.children[expectedChild.id]?.value?.id == expectedChild.id)
    }
  }

  @MainActor
  struct RemoveChild: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func childExists_removeChild_return_childRemovedFromChildren() {
      let configuration = Configuration()
      let expectedChild = BaseRouter(configuration: configuration)
      baseRouter.addChild(expectedChild)
      #expect(baseRouter.children[expectedChild.id] != nil)

      baseRouter.removeChild(expectedChild)

      #expect(baseRouter.children[expectedChild.id] == nil)
      #expect(baseRouter.children.isEmpty)
    }

    @Test
    func childDoesNotExist_removeChild_return_noChange() {
      let configuration = Configuration()
      let expectedChild = BaseRouter(configuration: configuration)
      #expect(baseRouter.children.isEmpty)

      baseRouter.removeChild(expectedChild)

      #expect(baseRouter.children.isEmpty)
    }
  }

  @MainActor
  struct ClearChildren: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func childrenExist_clearChildren_return_emptyChildren() {
      let configuration = Configuration()
      let expectedFirstChild = BaseRouter(configuration: configuration)
      let expectedSecondChild = BaseRouter(configuration: configuration)
      baseRouter.addChild(expectedFirstChild)
      baseRouter.addChild(expectedSecondChild)
      #expect(baseRouter.children.count == 2)

      baseRouter.clearChildren()

      #expect(baseRouter.children.isEmpty)
    }
  }

  @MainActor
  struct FindTab: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func matchingTabExists_findTab_return_routerForTab() {
      let expectedRouterInTab = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .tab("home", hideTabBarOnPush: false),
        parent: baseRouter
      )

      let foundRouter = baseRouter.find(tab: TestTabRoute.home)

      #expect(foundRouter?.id == expectedRouterInTab.id)
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
      let expectedTabRouter = TabRouter(tab: TestTabRoute.home, parent: baseRouter)

      #expect(baseRouter.tabRouter?.id == expectedTabRouter.id)
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
      let expectedTabRouter = TabRouter(tab: TestTabRoute.home, parent: baseRouter)

      let foundTabRouter = baseRouter.tabRouter(for: TestTabRoute.settings)

      #expect(foundTabRouter?.id == expectedTabRouter.id)
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
      let expectedTabRouter = TabRouter(tab: TestTabRoute.home, parent: baseRouter)
      let expectedRouterInTab = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .tab("home", hideTabBarOnPush: false),
        parent: expectedTabRouter
      )

      let foundRouter = baseRouter.findRouterInTabRouter(for: TestTabRoute.home)

      #expect(foundRouter?.id == expectedRouterInTab.id)
    }
  }
}
