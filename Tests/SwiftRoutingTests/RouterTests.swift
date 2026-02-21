import Testing
import Combine
import Foundation
@testable import SwiftRouting

@MainActor
struct RouterTests {
  @MainActor
  struct CurrentRoute: RouterTestSuite {
    let router: Router

    @Test
    func pathIsEmpty_return_rootRoute() {
      #expect(router.path.isEmpty)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
    }

    @Test
    func pathIsNotEmpty_return_lastElementInPath() {
      router.push(TestRoute.details(id: "42"))
      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "42"))
    }
  }

  @MainActor
  struct IsPresented: RouterTestSuite {
    let router: Router

    @Test
    func routerTypeIsApp_return_false() {
      #expect(router.isPresented == false)
    }

    @Test
    func routerTypeIsPresented_return_true() {
      let presentedRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: router
      )

      #expect(presentedRouter.isPresented == true)
    }
  }

  @MainActor
  struct RouteCount: RouterTestSuite {
    let router: Router

    @Test
    func pathIsEmpty_return_one() {
      #expect(router.path.isEmpty)
      #expect(router.routeCount == 1)
    }

    @Test
    func pathHasOneElement_return_two() {
      router.push(TestRoute.details(id: "42"))
      #expect(router.routeCount == 2)
    }

    @Test
    func pathIsClearedWithPopToRoot_return_one() {
      router.push(TestRoute.home)
      router.push(TestRoute.settings)
      #expect(router.routeCount == 3)

      router.popToRoot()
      #expect(router.routeCount == 1)
    }
  }

  @MainActor
  struct Sheet: RouterTestSuite {
    let router: Router

    @Test
    func presentIsCalled_return_trueWithCurrentRouter() {
      var cancellables = Set<AnyCancellable>()
      var receivedIsPresented: Bool?
      var receivedRouter: BaseRouter?

      router.present
        .sink { isPresented, emittedRouter in
          receivedIsPresented = isPresented
          receivedRouter = emittedRouter
        }
        .store(in: &cancellables)

      router.present(TestRoute.settings)

      #expect(receivedIsPresented == true)
      #expect(receivedRouter?.id == router.id)
      #expect((router.sheet?.wrapped as? TestRoute) == .settings)
    }

    @Test
    func dismissIsCalled_return_falseWithCurrentRouter() {
      var cancellables = Set<AnyCancellable>()
      var receivedIsPresented: Bool?
      var receivedRouter: BaseRouter?

      router.present(TestRoute.settings)
      router.present
        .sink { isPresented, emittedRouter in
          receivedIsPresented = isPresented
          receivedRouter = emittedRouter
        }
        .store(in: &cancellables)

      router.sheet = nil

      #expect(receivedIsPresented == false)
      #expect(receivedRouter?.id == router.id)
      #expect(router.sheet == nil)
    }
  }

  @MainActor
  struct Cover: RouterTestSuite {
    let router: Router

    @Test
    func presentIsCalled_return_trueWithCurrentRouter() {
      var cancellables = Set<AnyCancellable>()
      var receivedIsPresented: Bool?
      var receivedRouter: BaseRouter?

      router.present
        .sink { isPresented, emittedRouter in
          receivedIsPresented = isPresented
          receivedRouter = emittedRouter
        }
        .store(in: &cancellables)

      router.cover(TestRoute.settings)

      #expect(receivedIsPresented == true)
      #expect(receivedRouter?.id == router.id)
      #expect((router.cover?.wrapped as? TestRoute) == .settings)
    }

    @Test
    func dismissIsCalled_return_falseWithCurrentRouter() {
      var cancellables = Set<AnyCancellable>()
      var receivedIsPresented: Bool?
      var receivedRouter: BaseRouter?

      router.cover(TestRoute.settings)
      router.present
        .sink { isPresented, emittedRouter in
          receivedIsPresented = isPresented
          receivedRouter = emittedRouter
        }
        .store(in: &cancellables)

      router.cover = nil

      #expect(receivedIsPresented == false)
      #expect(receivedRouter?.id == router.id)
      #expect(router.cover == nil)
    }
  }

  @MainActor
  struct UpdateRoot: RouterTestSuite {
    let router: Router

    @Test
    func pathIsEmpty_updateRoot_return_newRootRoute() {
      router.update(root: TestRoute.settings)

      #expect((router.root.wrapped as? TestRoute) == .settings)
      #expect((router.currentRoute.wrapped as? TestRoute) == .settings)
      #expect(router.path.isEmpty)
    }
  }

  @MainActor
  struct PushRoute: RouterTestSuite {
    let router: Router

    @Test
    func pathIsEmpty_push_return_oneElementInPath() {
      router.push(TestRoute.home)

      #expect(router.path.count == 1)
      #expect((router.path.last?.wrapped as? TestRoute) == .home)
      #expect((router.currentRoute.wrapped as? TestRoute) == .home)
    }

    @Test
    func pathHasElements_push_return_newLastElementInPath() {
      router.push(TestRoute.home)
      router.push(TestRoute.details(id: "42"))

      #expect(router.path.count == 2)
      #expect((router.path.last?.wrapped as? TestRoute) == .details(id: "42"))
      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "42"))
    }
  }

  @MainActor
  struct PresentRoute: RouterTestSuite {
    let router: Router

    @Test
    func withStackTrue_return_sheetInStackTrue() {
      router.present(TestRoute.settings, withStack: true)

      #expect((router.sheet?.wrapped as? TestRoute) == .settings)
      #expect(router.sheet?.inStack == true)
    }

    @Test
    func withStackFalse_return_sheetInStackFalse() {
      router.present(TestRoute.settings, withStack: false)

      #expect((router.sheet?.wrapped as? TestRoute) == .settings)
      #expect(router.sheet?.inStack == false)
    }
  }

  @MainActor
  struct CoverRoute: RouterTestSuite {
    let router: Router

    @Test
    func pathIsEmpty_cover_return_coverRouteAndKeepCurrentRouteAsRoot() {
      router.cover(TestRoute.settings)

      #expect((router.cover?.wrapped as? TestRoute) == .settings)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
      #expect(router.path.isEmpty)
    }
  }

  @MainActor
  struct Route: RouterTestSuite {
    let router: Router

    @Test
    func routeTypePush_return_elementInPath() {
      router.route(TestDispatchRoute.pushed)

      #expect(router.path.count == 1)
      #expect((router.path.last?.wrapped as? TestDispatchRoute) == .pushed)
      #expect((router.currentRoute.wrapped as? TestDispatchRoute) == .pushed)
    }

    @Test
    func routeTypeRoot_return_updatedRoot() {
      router.route(TestDispatchRoute.rooted)

      #expect((router.root.wrapped as? TestDispatchRoute) == .rooted)
      #expect((router.currentRoute.wrapped as? TestDispatchRoute) == .rooted)
      #expect(router.path.isEmpty)
    }

    @Test
    func routeTypeCover_return_updatedCover() {
      router.route(TestDispatchRoute.covered)

      #expect((router.cover?.wrapped as? TestDispatchRoute) == .covered)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
    }

    @Test
    func routeTypeSheetWithStack_return_updatedSheetWithInStackTrue() {
      router.route(TestDispatchRoute.sheetWithStack)

      #expect((router.sheet?.wrapped as? TestDispatchRoute) == .sheetWithStack)
      #expect(router.sheet?.inStack == true)
    }

    @Test
    func routeTypeSheetWithoutStack_return_updatedSheetWithInStackFalse() {
      router.route(TestDispatchRoute.sheetWithoutStack)

      #expect((router.sheet?.wrapped as? TestDispatchRoute) == .sheetWithoutStack)
      #expect(router.sheet?.inStack == false)
    }
  }

  @MainActor
  struct PopToRoot: RouterTestSuite {
    let router: Router

    @Test
    func pathHasElements_popToRoot_return_emptyPath() {
      router.push(TestRoute.home)
      router.push(TestRoute.details(id: "42"))
      #expect(router.path.count == 2)

      router.popToRoot()

      #expect(router.path.isEmpty)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
    }
  }

  @MainActor
  struct Back: RouterTestSuite {
    let router: Router

    @Test
    func pathHasElements_back_return_removeLastElement() {
      router.push(TestRoute.home)
      router.push(TestRoute.details(id: "42"))
      #expect(router.path.count == 2)

      router.back()

      #expect(router.path.count == 1)
      #expect((router.currentRoute.wrapped as? TestRoute) == .home)
    }

    @Test
    func pathIsEmpty_back_return_noChange() {
      router.back()

      #expect(router.path.isEmpty)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
    }
  }

  @MainActor
  struct Close: RouterTestSuite {
    let router: Router

    @Test
    func routerTypeIsApp_close_return_triggerCloseFalse() {
      router.close()
      #expect(router.triggerClose == false)
    }

    @Test
    func routerTypeIsPresented_close_return_triggerCloseTrue() {
      let presentedRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: router
      )

      presentedRouter.close()
      #expect(presentedRouter.triggerClose == true)
    }
  }
}
