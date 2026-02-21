import Testing
@testable import SwiftRouting

@MainActor
struct RouterTests {
  let router: Router

  init() {
    self.router = Router(configuration: .default)
  }

  @MainActor
  enum CurrentRoute {
    @Test
    static func pathIsEmpty_return_rootRoute() {
      let router = RouterTests().router
      #expect(router.path.isEmpty)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
    }

    @Test
    static func pathIsNotEmpty_return_lastElementInPath() {
      let router = RouterTests().router
      router.push(TestRoute.details(id: "42"))
      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "42"))
    }
  }

  @MainActor
  enum IsPresented {
    @Test
    static func routerTypeIsApp_return_false() {
      let router = RouterTests().router
      #expect(router.isPresented == false)
    }

    @Test
    static func routerTypeIsPresented_return_true() {
      let parent = Router(configuration: .default)
      let presentedRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: parent
      )

      #expect(presentedRouter.isPresented == true)
    }
  }
}
