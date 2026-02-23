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
}
