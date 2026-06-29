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
    func pathHasOneElement_return_lastElementInPath() {
      router.push(TestRoute.details(id: "42"))

      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "42"))
    }

    @Test
    func pathHasMultipleElements_return_lastElementInPath() {
      router.push(TestRoute.home)
      router.push(TestRoute.settings)
      router.push(TestRoute.details(id: "42"))

      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "42"))
    }

    @Test
    func sheetPresented_return_currentRouteUnchanged() {
      router.push(TestRoute.home)
      router.present(TestRoute.settings)

      #expect((router.currentRoute.wrapped as? TestRoute) == .home)
    }

    @Test
    func coverPresented_return_currentRouteUnchanged() {
      router.push(TestRoute.home)
      router.cover(TestRoute.settings)

      #expect((router.currentRoute.wrapped as? TestRoute) == .home)
    }

    @Test
    func splitRouter_noSelection_return_root() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: true),
        parent: parentRouter
      )

      #expect(splitRouter.currentRoute.wrapped is DefaultRoute)
    }

    @Test
    func splitRouter_withDetailSelection_return_detailRoute() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
      splitRouter.select(detail: "any")

      #expect(splitRouter.currentRoute.wrapped is TestRoute)
    }

    @Test
    func splitRouter_withContentSelection_return_contentRoute() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: true),
        parent: parentRouter,
        contentRouteFactory: { _ in AnyRoute(wrapped: TestRoute.settings) }
      )
      splitRouter.contentSelection = AnyHashable("any")

      #expect((splitRouter.currentRoute.wrapped as? TestRoute) == .settings)
    }

    @Test
    func splitRouter_pathHasElements_return_lastPathElement() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
      splitRouter.push(TestRoute.settings)

      #expect((splitRouter.currentRoute.wrapped as? TestRoute) == .settings)
    }

    @Test
    func splitRouter_pathAndDetailSelected_return_pathRoute() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
      splitRouter.select(detail: "any")
      splitRouter.push(TestRoute.settings)

      #expect((splitRouter.currentRoute.wrapped as? TestRoute) == .settings)
    }

    @Test
    func splitRouter_detailAndContentSelected_return_detailRoute() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: true),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) },
        contentRouteFactory: { _ in AnyRoute(wrapped: TestRoute.settings) }
      )
      splitRouter.contentSelection = AnyHashable("content")
      splitRouter.select(detail: "detail")

      #expect((splitRouter.currentRoute.wrapped as? TestRoute) == .home)
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

    @Test
    func splitRouter_noSelection_return_one() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .split(DefaultRoute.main.name, hasContentColumn: true), parent: parentRouter)

      #expect(splitRouter.routeCount == 1)
    }

    @Test
    func splitRouter_withDetailSelection_return_two() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
      splitRouter.select(detail: "any")

      #expect(splitRouter.routeCount == 2)
    }

    @Test
    func splitRouter_withContentAndDetailSelection_return_three() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: true),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) },
        contentRouteFactory: { _ in AnyRoute(wrapped: TestRoute.settings) }
      )
      splitRouter.contentSelection = AnyHashable("content")
      splitRouter.select(detail: "detail")

      #expect(splitRouter.routeCount == 3)
    }

    @Test
    func splitRouter_detailSelectedAndPathPushed_return_three() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
      splitRouter.select(detail: "any")
      splitRouter.push(TestRoute.settings)

      #expect(splitRouter.routeCount == 3)
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
  struct RemoveContextOnRootChange {
    @Test
    func contextExistsOnRoot_updateRoot_return_rootContextRemovedAndLoggerCalled() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.add(context: StringContext.self) { _ in }
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.update(root: TestRoute.settings)

      #expect(expectedRouter.contexts.all(for: StringContext.self).isEmpty)
      assertLogMessagesContain(
        expectedLoggerSpy,
        expected: .context(.remove(DefaultRoute.main, context: StringContext.self))
      )
    }

    @Test
    func multipleContextsOnRoot_updateRoot_return_allRootContextsRemovedAndLoggerCalled() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.add(context: StringContext.self) { _ in }
      expectedRouter.add(context: IntContext.self) { _ in }
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      #expect(expectedRouter.contexts.all(for: IntContext.self).count == 1)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.update(root: TestRoute.settings)

      #expect(expectedRouter.contexts.all(for: StringContext.self).isEmpty)
      #expect(expectedRouter.contexts.all(for: IntContext.self).isEmpty)
      assertLogMessagesContain(
        expectedLoggerSpy,
        expected: .context(.remove(DefaultRoute.main, context: StringContext.self))
      )
      assertLogMessagesContain(
        expectedLoggerSpy,
        expected: .context(.remove(DefaultRoute.main, context: IntContext.self))
      )
    }

    @Test
    func noContextOnRoot_updateRoot_return_noContextRemoveLoggerCall() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.update(root: TestRoute.settings)

      let hasContextRemoveLog = expectedLoggerSpy.receivedMessages.contains { message in
        if case .context(.remove(_, context: _)) = message { return true }
        return false
      }
      #expect(hasContextRemoveLog == false)
    }

    @Test
    func contextExistsOnNonRootRoute_updateRoot_return_nonRootContextPreserved() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedRouter.add(context: StringContext.self) { _ in }
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.update(root: TestRoute.settings)

      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      let hasContextRemoveLog = expectedLoggerSpy.receivedMessages.contains { message in
        if case .context(.remove(_, context: _)) = message { return true }
        return false
      }
      #expect(hasContextRemoveLog == false)
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

  // MARK: - Presentation

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

  // MARK: - Split

  @MainActor
  struct Init {

    @Test
    func parentProvided_init_return_attachedToParent() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .split(DefaultRoute.main.name, hasContentColumn: false), parent: parentRouter)

      #expect(parentRouter.children[splitRouter.id]?.value?.id == splitRouter.id)
    }

    @Test
    func parentProvided_init_return_sheetAndCoverNil() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .split(DefaultRoute.main.name, hasContentColumn: false), parent: parentRouter)

      #expect(splitRouter.sheet == nil)
      #expect(splitRouter.cover == nil)
    }

    @Test
    func hasContentColumn_return_false() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .split(DefaultRoute.main.name, hasContentColumn: false), parent: parentRouter)

      #expect(splitRouter.hasContentColumn == false)
    }

    @Test
    func withContent_hasContentColumn_return_true() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .split(DefaultRoute.main.name, hasContentColumn: true), parent: parentRouter)

      #expect(splitRouter.hasContentColumn == true)
    }

    @Test
    func stackRouter_hasContentColumn_return_false() {
      let parentRouter = Router(configuration: Configuration())
      let stackRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .stack(DefaultRoute.main.name), parent: parentRouter)

      #expect(stackRouter.hasContentColumn == false)
    }

    @Test
    func noSelection_currentRoute_return_root() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )

      #expect(splitRouter.currentRoute.wrapped is DefaultRoute)
    }

    @Test
    func withDetailSelection_currentRoute_return_detailRoute() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
      splitRouter.select(detail: "any")

      #expect(splitRouter.currentRoute.wrapped is TestRoute)
    }
  }

  @MainActor
  struct Select {
    let parentRouter: Router
    let splitRouter: Router

    init() {
      parentRouter = Router(configuration: Configuration())
      splitRouter = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: false),
        parent: parentRouter,
        detailRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
    }

    @Test
    func selectDetail_return_detailSelectionSet() {
      splitRouter.select(detail: "test")

      #expect(splitRouter.detailSelection == AnyHashable("test"))
    }

    @Test
    func selectContent_return_contentSelectionSet() {
      let router = Router(
        root: AnyRoute(wrapped: DefaultRoute.main),
        type: .split(DefaultRoute.main.name, hasContentColumn: true),
        parent: parentRouter,
        contentRouteFactory: { _ in AnyRoute(wrapped: TestRoute.home) }
      )
      router.select(content: "test")

      #expect(router.contentSelection == AnyHashable("test"))
    }

    @Test
    func stackRouter_selectDetail_return_noOp() {
      let stackRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .stack(DefaultRoute.main.name), parent: parentRouter)
      stackRouter.select(detail: "test")

      #expect(stackRouter.detailSelection == nil)
    }
  }

  @MainActor
  struct DetailBinding {
    let parentRouter: Router
    let splitRouter: Router

    init() {
      let pair = makeSplitRouterPair()
      parentRouter = pair.parent
      splitRouter = pair.split
    }

    @Test
    func detailBinding_return_nil() {
      let binding = splitRouter.detailBinding(as: String.self)

      #expect(binding.wrappedValue == nil)
    }

    @Test
    func detailBinding_set_return_detailSelectionUpdated() {
      let binding = splitRouter.detailBinding(as: String.self)
      binding.wrappedValue = "test"

      #expect(splitRouter.detailSelection == AnyHashable("test"))
    }

    @Test
    func selectionSet_detailBinding_return_selectedValue() {
      splitRouter.detailSelection = AnyHashable("test")
      let binding = splitRouter.detailBinding(as: String.self)

      #expect(binding.wrappedValue == "test")
    }

    @Test
    func detailBinding_setNil_return_detailSelectionNil() {
      splitRouter.detailSelection = AnyHashable("test")
      let binding = splitRouter.detailBinding(as: String.self)
      binding.wrappedValue = nil

      #expect(splitRouter.detailSelection == nil)
    }

    @Test
    func stackRouter_detailBinding_return_nil() {
      let stackRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .stack(DefaultRoute.main.name), parent: parentRouter)
      let binding = stackRouter.detailBinding(as: String.self)

      #expect(binding.wrappedValue == nil)
    }
  }

  @MainActor
  struct ContentBinding {
    let parentRouter: Router
    let splitRouter: Router

    init() {
      let pair = makeSplitRouterPair()
      parentRouter = pair.parent
      splitRouter = pair.split
    }

    @Test
    func contentBinding_return_nil() {
      let binding = splitRouter.contentBinding(as: String.self)

      #expect(binding.wrappedValue == nil)
    }

    @Test
    func contentBinding_set_return_contentSelectionUpdated() {
      let binding = splitRouter.contentBinding(as: String.self)
      binding.wrappedValue = "test"

      #expect(splitRouter.contentSelection == AnyHashable("test"))
    }

    @Test
    func selectionSet_contentBinding_return_selectedValue() {
      splitRouter.contentSelection = AnyHashable("test")
      let binding = splitRouter.contentBinding(as: String.self)

      #expect(binding.wrappedValue == "test")
    }

    @Test
    func contentBinding_setNil_return_contentSelectionNil() {
      splitRouter.contentSelection = AnyHashable("test")
      let binding = splitRouter.contentBinding(as: String.self)
      binding.wrappedValue = nil

      #expect(splitRouter.contentSelection == nil)
    }

    @Test
    func stackRouter_contentBinding_return_nil() {
      let stackRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .stack(DefaultRoute.main.name), parent: parentRouter)
      let binding = stackRouter.contentBinding(as: String.self)

      #expect(binding.wrappedValue == nil)
    }
  }

  // MARK: - Context

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
  struct RemoveContextOnPathChange {
    @Test
    func contextExistsOnRemovedRoute_back_return_contextRemovedAndLoggerCalled() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedRouter.add(context: StringContext.self) { _ in }
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.back()

      #expect(expectedRouter.contexts.all(for: StringContext.self).isEmpty)
      assertLogMessagesContain(
        expectedLoggerSpy,
        expected: .context(.remove(TestRoute.home, context: StringContext.self))
      )
    }

    @Test
    func multipleContextsExistOnRemovedRoutes_popToRoot_return_allContextsRemoved() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedRouter.add(context: StringContext.self) { _ in }
      expectedRouter.push(TestRoute.settings)
      expectedRouter.add(context: IntContext.self) { _ in }
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      #expect(expectedRouter.contexts.all(for: IntContext.self).count == 1)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.popToRoot()

      #expect(expectedRouter.contexts.all(for: StringContext.self).isEmpty)
      #expect(expectedRouter.contexts.all(for: IntContext.self).isEmpty)
      assertLogMessagesContain(
        expectedLoggerSpy,
        expected: .context(.remove(TestRoute.home, context: StringContext.self))
      )
      assertLogMessagesContain(
        expectedLoggerSpy,
        expected: .context(.remove(TestRoute.settings, context: IntContext.self))
      )
    }

    @Test
    func contextExistsOnRootOnly_back_return_rootContextPreserved() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.add(context: StringContext.self) { _ in }
      expectedRouter.push(TestRoute.home)
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.back()

      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
    }

    @Test
    func noContextOnRemovedRoute_back_return_noContextRemoveLoggerCall() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.back()

      let hasContextRemoveLog = expectedLoggerSpy.receivedMessages.contains { message in
        if case .context(.remove(_, context: _)) = message {
          return true
        }
        return false
      }
      #expect(hasContextRemoveLog == false)
    }

    @Test
    func contextExistsOnCurrentRoute_push_return_contextPreserved() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedRouter.add(context: StringContext.self) { _ in }
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.push(TestRoute.settings)

      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
    }

    @Test
    func multipleContextsSameTypeOnDifferentRoutes_backOne_return_onlyCurrentRouteContextRemoved() {
      let setup = makeRouterWithLoggerSpy()
      let expectedRouter = setup.router
      let expectedLoggerSpy = setup.loggerSpy
      expectedRouter.push(TestRoute.home)
      expectedRouter.add(context: StringContext.self) { _ in }
      expectedRouter.push(TestRoute.settings)
      expectedRouter.add(context: StringContext.self) { _ in }
      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 2)
      expectedLoggerSpy.clearReceivedMessages()

      expectedRouter.back()

      #expect(expectedRouter.contexts.all(for: StringContext.self).count == 1)
      assertLogMessagesContain(
        expectedLoggerSpy,
        expected: .context(.remove(TestRoute.settings, context: StringContext.self))
      )
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

  // MARK: - HandleDeeplink

  @MainActor
  struct HandleDeeplink: RouterTestSuite {
    let router: Router

    @Test
    func pathHasElements_handleDeeplink_return_pathClearedBeforeNavigation() {
      router.push(TestRoute.home)
      router.push(TestRoute.settings)
      #expect(router.path.count == 2)
      let deeplink = DeeplinkRoute.push(TestRoute.details(id: "new"))

      router.handle(deeplink: deeplink)

      #expect(router.path.count == 1)
      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "new"))
    }

    @Test
    func deeplinkWithRoot_handleDeeplink_return_rootUpdatedBeforeNavigation() {
      let deeplink = DeeplinkRoute.push(TestRoute.details(id: "after-root"), root: .home)

      router.handle(deeplink: deeplink)

      #expect((router.root.wrapped as? TestRoute) == .home)
      #expect(router.path.count == 1)
      #expect((router.currentRoute.wrapped as? TestRoute) == .details(id: "after-root"))
    }

    @Test
    func deeplinkWithPath_handleDeeplink_return_intermediateRoutesPushedBeforeFinal() {
      let deeplink = DeeplinkRoute.push(
        TestRoute.details(id: "final"),
        path: [.home, .settings]
      )

      router.handle(deeplink: deeplink)

      #expect(router.path.count == 3)
      #expect((router.path[0].wrapped as? TestRoute) == .home)
      #expect((router.path[1].wrapped as? TestRoute) == .settings)
      #expect((router.path[2].wrapped as? TestRoute) == .details(id: "final"))
    }

    @Test
    func deeplinkWithSheetType_handleDeeplink_return_sheetPresented() {
      let deeplink = DeeplinkRoute.present(TestRoute.settings)

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.sheet?.wrapped as? TestRoute) == .settings)
      #expect(router.sheet?.inStack == true)
    }

    @Test
    func deeplinkWithCoverType_handleDeeplink_return_coverPresented() {
      let deeplink = DeeplinkRoute.cover(TestRoute.settings)

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.cover?.wrapped as? TestRoute) == .settings)
    }

    @Test
    func deeplinkPopToRoot_handleDeeplink_return_pathClearedAndNoNavigation() {
      router.push(TestRoute.home)
      router.push(TestRoute.settings)
      #expect(router.path.count == 2)
      let deeplink = DeeplinkRoute<TestRoute>.popToRoot()

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.currentRoute.wrapped as? DefaultRoute) == .main)
    }

    @Test
    func deeplinkUpdateRoot_handleDeeplink_return_rootUpdatedAndNoNavigation() {
      let deeplink = DeeplinkRoute.updateRoot(TestRoute.home)

      router.handle(deeplink: deeplink)

      #expect(router.path.isEmpty)
      #expect((router.root.wrapped as? TestRoute) == .home)
      #expect((router.currentRoute.wrapped as? TestRoute) == .home)
    }

    @Test
    func presentedChildExists_handleDeeplink_return_childClosedBeforeNavigation() {
      let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
      let expectedRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
      let expectedPresentedChild = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: expectedRouter
      )
      expectedRouter.sheet = AnyRoute(wrapped: TestRoute.home)
      #expect(expectedRouter.sheet != nil)
      #expect(expectedRouter.children[expectedPresentedChild.id] != nil)
      expectedLoggerSpy.clearReceivedMessages()
      let deeplink = DeeplinkRoute.push(TestRoute.settings)

      expectedRouter.handle(deeplink: deeplink)

      #expect(expectedRouter.sheet == nil)
      #expect((expectedRouter.currentRoute.wrapped as? TestRoute) == .settings)
      assertLogMessagesContain(expectedLoggerSpy, expected: .action(.closeChildren(expectedPresentedChild)))
      expectedLoggerSpy.clearReceivedMessages()
    }

    @Test
    func deeplinkWithRootPathAndRoute_handleDeeplink_return_fullNavigationSequence() {
      let deeplink = DeeplinkRoute.push(
        TestRoute.details(id: "final"),
        root: .home,
        path: [.settings]
      )

      router.handle(deeplink: deeplink)

      #expect((router.root.wrapped as? TestRoute) == .home)
      #expect(router.path.count == 2)
      #expect((router.path[0].wrapped as? TestRoute) == .settings)
      #expect((router.path[1].wrapped as? TestRoute) == .details(id: "final"))
    }
  }
}

@MainActor
private func makeRouterWithLoggerSpy() -> (router: Router, loggerSpy: LoggerSpy) {
  let expectedLoggerSpy = LoggerSpy(storesConfiguration: false)
  let expectedRouter = Router(configuration: Configuration(loggerSpy: expectedLoggerSpy))
  expectedLoggerSpy.clearReceivedMessages()
  return (expectedRouter, expectedLoggerSpy)
}

@MainActor
private func makeSplitRouterPair() -> (parent: Router, split: Router) {
  let parent = Router(configuration: Configuration())
  let split = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .split(DefaultRoute.main.name, hasContentColumn: false), parent: parent)
  return (parent, split)
}
