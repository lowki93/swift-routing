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
      var expectedBaseRouter: BaseRouter? = BaseRouter(configuration: Configuration(loggerSpy: loggerSpy), root: AnyRoute(wrapped: DefaultRoute.main))
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
      let expectedChild = BaseRouter(configuration: configuration, root: AnyRoute(wrapped: DefaultRoute.main))

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
      let expectedChild = BaseRouter(configuration: configuration, root: AnyRoute(wrapped: DefaultRoute.main))
      baseRouter.addChild(expectedChild)
      #expect(baseRouter.children[expectedChild.id] != nil)

      baseRouter.removeChild(expectedChild)

      #expect(baseRouter.children[expectedChild.id] == nil)
      #expect(baseRouter.children.isEmpty)
    }

    @Test
    func childDoesNotExist_removeChild_return_noChange() {
      let configuration = Configuration()
      let expectedChild = BaseRouter(configuration: configuration, root: AnyRoute(wrapped: DefaultRoute.main))
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
      let expectedFirstChild = BaseRouter(configuration: configuration, root: AnyRoute(wrapped: DefaultRoute.main))
      let expectedSecondChild = BaseRouter(configuration: configuration, root: AnyRoute(wrapped: DefaultRoute.main))
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
  struct RootRouter: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func noParent_rootRouter_return_self() {
      #expect(baseRouter.rootRouter.id == baseRouter.id)
    }

    @Test
    func hasAncestors_rootRouter_return_topMostAncestor() {
      let child = Router(root: AnyRoute(wrapped: TestRoute.home), type: .presented("sheet"), parent: baseRouter)
      let grandchild = Router(root: AnyRoute(wrapped: TestRoute.settings), type: .presented("sheet2"), parent: child)

      #expect(grandchild.rootRouter.id == baseRouter.id)
      #expect(child.rootRouter.id == baseRouter.id)
    }
  }

  @MainActor
  struct RouterTreeDescription: BaseRouterTestSuite {
    let baseRouter: BaseRouter

    @Test
    func noChildren_routerTreeDescription_return_singleLine() {
      #expect(baseRouter.routerTreeDescription() == "baseRouter — current: main")
    }

    @Test
    func oneChild_routerTreeDescription_return_childOnLastConnector() {
      let child = Router(root: AnyRoute(wrapped: TestRoute.home), type: .presented("sheet"), parent: baseRouter)

      let lines = baseRouter.routerTreeDescription().components(separatedBy: "\n")

      #expect(lines.count == 2)
      #expect(lines[0] == "baseRouter — current: main")
      #expect(lines[1] == "└─ \(child.description) — current: home")
    }

    @Test
    func multipleChildren_routerTreeDescription_return_allButLastOnBranchConnector() {
      let childA = Router(root: AnyRoute(wrapped: TestRoute.home), type: .presented("sheet"), parent: baseRouter)
      let childB = Router(root: AnyRoute(wrapped: TestRoute.settings), type: .presented("sheet2"), parent: baseRouter)
      // `children` is a Dictionary with no defined iteration order -- the tree sorts by
      // `id.uuidString`, so compute the expected order the same way instead of assuming
      // insertion order.
      let ordered = [childA, childB].sorted { $0.id.uuidString < $1.id.uuidString }
      let expectedRoute: (Router) -> String = { $0.id == childA.id ? "home" : "settings" }

      let lines = baseRouter.routerTreeDescription().components(separatedBy: "\n")

      #expect(lines.count == 3)
      #expect(lines[1] == "├─ \(ordered[0].description) — current: \(expectedRoute(ordered[0]))")
      #expect(lines[2] == "└─ \(ordered[1].description) — current: \(expectedRoute(ordered[1]))")
    }

    @Test
    func calledFromNestedChild_routerTreeDescription_return_fullTreeFromRoot() {
      let child = Router(root: AnyRoute(wrapped: TestRoute.home), type: .presented("sheet"), parent: baseRouter)

      #expect(child.routerTreeDescription() == baseRouter.routerTreeDescription())
    }

    @Test
    func nestedGrandchild_routerTreeDescription_return_indentedTwice() {
      let child = Router(root: AnyRoute(wrapped: TestRoute.home), type: .presented("sheet"), parent: baseRouter)
      let grandchild = Router(root: AnyRoute(wrapped: TestRoute.settings), type: .presented("sheet2"), parent: child)

      let lines = baseRouter.routerTreeDescription().components(separatedBy: "\n")

      #expect(lines.count == 3)
      #expect(lines[1] == "└─ \(child.description) — current: home")
      #expect(lines[2] == "   └─ \(grandchild.description) — current: settings")
    }

    @Test
    func routerHasRegisteredContext_routerTreeDescription_return_contextOnOwnLine() {
      baseRouter.add(context: StringContext.self) { _ in }

      let lines = baseRouter.routerTreeDescription().components(separatedBy: "\n")

      #expect(lines.count == 2)
      #expect(lines[0] == "baseRouter — current: main")
      #expect(lines[1] == "   contexts: [StringContext]")
    }

    @Test
    func routerHasMultipleRegisteredContexts_routerTreeDescription_return_contextsSortedAlphabetically() {
      baseRouter.add(context: IntContext.self) { _ in }
      baseRouter.add(context: StringContext.self) { _ in }

      let lines = baseRouter.routerTreeDescription().components(separatedBy: "\n")

      #expect(lines.count == 2)
      #expect(lines[1] == "   contexts: [IntContext, StringContext]")
    }

    @Test
    func noRegisteredContext_routerTreeDescription_return_noContextsLine() {
      #expect(baseRouter.routerTreeDescription().contains("contexts:") == false)
    }

    @Test
    func childHasRegisteredContext_routerTreeDescription_return_contextIndentedUnderChild() {
      let child = Router(root: AnyRoute(wrapped: TestRoute.home), type: .presented("sheet"), parent: baseRouter)
      child.add(context: StringContext.self) { _ in }

      let lines = baseRouter.routerTreeDescription().components(separatedBy: "\n")

      #expect(lines.count == 3)
      #expect(lines[1] == "└─ \(child.description) — current: home")
      #expect(lines[2] == "      contexts: [StringContext]")
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
