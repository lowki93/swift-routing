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
      let expectedPresentedRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: router
      )

      #expect(expectedPresentedRouter.isPresented == true)
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

    @Test
    func pathIsEmpty_updateRoot_return_loggerCalledWithNavigationRoot() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy

      expectedRouter.update(root: TestRoute.settings)

      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .navigation(from: DefaultRoute.main, to: TestRoute.settings, type: .root)
      )
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

    @Test
    func pathIsEmpty_push_return_loggerCalledWithNavigationPush() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy

      expectedRouter.push(TestRoute.home)

      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .navigation(from: DefaultRoute.main, to: TestRoute.home, type: .push)
      )
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

    @Test
    func withStackTrue_return_loggerCalledWithNavigationSheet() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy

      expectedRouter.present(TestRoute.settings, withStack: true)

      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .navigation(from: DefaultRoute.main, to: TestRoute.settings, type: .sheet(withStack: true))
      )
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

    @Test
    func pathIsEmpty_cover_return_loggerCalledWithNavigationCover() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy

      expectedRouter.cover(TestRoute.settings)

      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .navigation(from: DefaultRoute.main, to: TestRoute.settings, type: .cover)
      )
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

    @Test
    func pathHasElements_popToRoot_return_loggerCalledWithActionPopToRoot() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.popToRoot()

      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(expectedLoggerSpy, is: .action(.popToRoot))
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

    @Test
    func pathHasElements_back_return_loggerCalledWithActionBack() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.back()

      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(expectedLoggerSpy, is: .action(.back()))
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
      let expectedPresentedRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: router
      )

      expectedPresentedRouter.close()
      #expect(expectedPresentedRouter.triggerClose == true)
    }

    @Test
    func routerTypeIsPresented_close_return_loggerCalledWithActionClose() {
      let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedParentRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
      let expectedPresentedRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: expectedParentRouter
      )
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedPresentedRouter.close()

      #expect(expectedLoggerSpy.receivedRouterId == expectedPresentedRouter.id)
      assertLogMessageKind(expectedLoggerSpy, is: .action(.close))
    }
  }

  @MainActor
  struct AddContext: RouterTestSuite {
    let router: Router

    @Test
    func contextTypeIsAdded_addContext_return_contextRegistered() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy

      expectedRouter.add(context: StringContext.self) { _ in }

      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .context(.add(DefaultRoute.main, context: StringContext.self))
      )
    }

    @Test
    func contextTypeAlreadyRegistered_addContext_return_noDuplicateContext() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.add(context: StringContext.self) { _ in }
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil
      expectedRouter.add(context: StringContext.self) { _ in }

      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      #expect(expectedLoggerSpy.receivedMessage == nil)
    }
  }

  @MainActor
  struct RemoveContext: RouterTestSuite {
    let router: Router

    @Test
    func contextTypeIsRegistered_removeContext_return_contextRemovedAndLoggerCalled() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.add(context: StringContext.self) { _ in }
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.remove(context: StringContext.self)

      #expect(expectedRouter.contexts.all(for: StringContext.self).isEmpty)
      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .context(.remove(DefaultRoute.main, context: StringContext.self))
      )
    }

    @Test
    func contextTypeIsNotRegistered_removeContext_return_noChangeAndNoLoggerCall() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.remove(context: StringContext.self)

      #expect(expectedRouter.contexts.all(for: StringContext.self).isEmpty)
      #expect(expectedLoggerSpy.receivedMessage == nil)
    }

    @Test
    func contextTypeIsRegisteredOnRootAndCurrentRouteDiffers_removeContext_return_noChangeAndNoLoggerCall() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.add(context: StringContext.self) { _ in }
      expectedRouter.push(TestRoute.home)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.remove(context: StringContext.self)

      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      #expect(expectedLoggerSpy.receivedMessage == nil)
    }
  }

  @MainActor
  struct Terminate: RouterTestSuite {
    let router: Router

    @Test
    func contextExistsInPreviousRoute_terminate_return_popToContextRouteAndLoggerBackCount() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      var receivedContext: StringContext?

      expectedRouter.push(TestRoute.home)
      expectedRouter.add(context: StringContext.self) { context in
        receivedContext = context
      }
      expectedRouter.push(TestRoute.settings)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.terminate(StringContext(value: "42"))

      #expect(receivedContext == StringContext(value: "42"))
      #expect(expectedRouter.path.count == 1)
      #expect((expectedRouter.currentRoute.wrapped as? TestRoute) == .home)
      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(expectedLoggerSpy, is: .action(.back(count: 1)))
    }

    @Test
    func contextDoesNotExistAndRouterIsPresented_terminate_return_triggerCloseTrueAndLoggerClose() {
      let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedParentRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
      let expectedPresentedRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: expectedParentRouter
      )
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedPresentedRouter.terminate(StringContext(value: "42"))

      #expect(expectedPresentedRouter.triggerClose == true)
      #expect(expectedLoggerSpy.receivedRouterId == expectedPresentedRouter.id)
      assertLogMessageKind(expectedLoggerSpy, is: .action(.close))
    }

    @Test
    func contextDoesNotExistAndPathHasElements_terminate_return_backOneAndLoggerBack() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedRouter.push(TestRoute.settings)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.terminate(StringContext(value: "42"))

      #expect(expectedRouter.path.count == 1)
      #expect((expectedRouter.currentRoute.wrapped as? TestRoute) == .home)
      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(expectedLoggerSpy, is: .action(.back()))
    }

    @Test
    func contextDoesNotExistAndPathIsEmpty_terminate_return_noChangeAndNoLoggerCall() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.terminate(StringContext(value: "42"))

      #expect(expectedRouter.path.isEmpty)
      #expect((expectedRouter.currentRoute.wrapped as? DefaultRoute) == .main)
      #expect(expectedLoggerSpy.receivedMessage == nil)
    }
  }

  @MainActor
  struct Context: RouterTestSuite {
    let router: Router

    @Test
    func matchingContextExistsInParentAndCurrent_context_return_executeBoth() {
      let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedParentRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
      let expectedChildRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: expectedParentRouter
      )
      var expectedParentReceivedContext: StringContext?
      var expectedChildReceivedContext: StringContext?

      expectedParentRouter.add(context: StringContext.self) { context in
        expectedParentReceivedContext = context
      }
      expectedChildRouter.add(context: StringContext.self) { context in
        expectedChildReceivedContext = context
      }
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedChildRouter.context(StringContext(value: "42"))

      #expect(expectedParentReceivedContext == StringContext(value: "42"))
      #expect(expectedChildReceivedContext == StringContext(value: "42"))
      #expect(expectedLoggerSpy.receivedRouterId == expectedChildRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .context(.execute(StringContext(value: "42"), from: TestRoute.home))
      )
    }

    @Test
    func matchingContextDoesNotExist_context_return_noActionAndNoLoggerCall() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      var expectedReceivedIntContext: IntContext?
      expectedRouter.add(context: IntContext.self) { context in
        expectedReceivedIntContext = context
      }
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.context(StringContext(value: "42"))

      #expect(expectedReceivedIntContext == nil)
      #expect(expectedLoggerSpy.receivedMessage == nil)
    }

    @Test
    func matchingContextExistsOnlyInParent_context_return_executeParentAndLoggerFromParent() {
      let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedParentRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
      let expectedChildRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: expectedParentRouter
      )
      var expectedParentReceivedContext: StringContext?
      expectedParentRouter.add(context: StringContext.self) { context in
        expectedParentReceivedContext = context
      }
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedChildRouter.context(StringContext(value: "42"))

      #expect(expectedParentReceivedContext == StringContext(value: "42"))
      #expect(expectedLoggerSpy.receivedRouterId == expectedParentRouter.id)
      assertLogMessageKind(
        expectedLoggerSpy,
        is: .context(.execute(StringContext(value: "42"), from: DefaultRoute.main))
      )
    }
  }

  @MainActor
  struct CloseChildren: RouterTestSuite {
    let router: Router

    @Test
    func noPresentedChild_closeChildren_return_noChangeAndNoLoggerCall() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.sheet = AnyRoute(wrapped: TestRoute.home)
      expectedRouter.cover = AnyRoute(wrapped: TestRoute.settings)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.closeChildren()

      #expect((expectedRouter.sheet?.wrapped as? TestRoute) == .home)
      #expect((expectedRouter.cover?.wrapped as? TestRoute) == .settings)
      #expect(expectedLoggerSpy.receivedMessage == nil)
    }

    @Test
    func presentedChildrenExist_closeChildren_return_sheetAndCoverNil() {
      let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
      let expectedPresentedSheetChild = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: expectedRouter
      )
      let expectedPresentedCoverChild = Router(
        root: AnyRoute(wrapped: TestRoute.settings),
        type: .presented("cover"),
        parent: expectedRouter
      )
      expectedRouter.sheet = AnyRoute(wrapped: TestRoute.home)
      expectedRouter.cover = AnyRoute(wrapped: TestRoute.settings)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil
      expectedLoggerSpy.receivedCallCount = 0

      #expect(expectedPresentedSheetChild.id != expectedPresentedCoverChild.id)
      expectedRouter.closeChildren()

      #expect(expectedRouter.sheet == nil)
      #expect(expectedRouter.cover == nil)
      #expect(expectedLoggerSpy.receivedCallCount == 2)
      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      let expectedIsCloseChildrenLog: Bool
      if case .action(.closeChildren(_))? = expectedLoggerSpy.receivedMessage {
        expectedIsCloseChildrenLog = true
      } else {
        expectedIsCloseChildrenLog = false
      }
      #expect(expectedIsCloseChildrenLog)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil
      expectedLoggerSpy.receivedCallCount = 0
    }

    @Test
    func presentedChildExists_closeChildren_return_loggerCalledWithActionCloseChildren() {
      let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
      let expectedPresentedChild = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: expectedRouter
      )
      expectedRouter.sheet = AnyRoute(wrapped: TestRoute.home)
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil

      expectedRouter.closeChildren()

      #expect(expectedLoggerSpy.receivedRouterId == expectedRouter.id)
      assertLogMessageKind(expectedLoggerSpy, is: .action(.closeChildren(expectedPresentedChild)))
      // Clear the retained message payload before child deallocation to avoid reentrant logger writes.
      expectedLoggerSpy.receivedMessage = nil
      expectedLoggerSpy.receivedRouterId = nil
    }
  }
}

@MainActor
private func makeRouterWithLoggerSpy() -> (router: Router, loggerSpy: LoggerSpy) {
  let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
  let expectedRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
  expectedLoggerSpy.receivedMessage = nil
  expectedLoggerSpy.receivedRouterId = nil
  expectedLoggerSpy.receivedCallCount = 0
  return (expectedRouter, expectedLoggerSpy)
}
