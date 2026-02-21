import Testing
import Combine
import Foundation
@testable import SwiftRouting

@MainActor
struct RouterTests {
  @MainActor
  struct CurrentRoute: RouterTestSuite {
    let router: Router

    init(router: Router) {
      self.router = router
    }

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

    init(router: Router) {
      self.router = router
    }

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

    init(router: Router) {
      self.router = router
    }

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

    init(router: Router) {
      self.router = router
    }

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

    init(router: Router) {
      self.router = router
    }

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
}
