import Testing
@testable import SwiftRouting

@MainActor
struct SplitRouterTests {

  @MainActor
  struct Init {
    @Test
    func parentProvided_init_return_splitRouterAttachedToParent() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = SplitRouter(parent: parentRouter)

      #expect(parentRouter.children[splitRouter.id]?.value?.id == splitRouter.id)
    }

    @Test
    func parentProvided_init_return_sheetNil() {
      let parentRouter = Router(configuration: Configuration())
      let splitRouter = SplitRouter(parent: parentRouter)

      #expect(splitRouter.sheet == nil)
      #expect(splitRouter.cover == nil)
    }
  }

  @MainActor
  struct Present: SplitRouterTestSuite {
    let parentRouter: Router
    let splitRouter: SplitRouter

    @Test
    func routeProvided_present_return_sheetSet() {
      splitRouter.present(TestRoute.home)

      #expect((splitRouter.sheet?.wrapped as? TestRoute) == .home)
    }

    @Test
    func routeProvided_present_return_sheetInStack() {
      splitRouter.present(TestRoute.home)

      #expect(splitRouter.sheet?.inStack == true)
    }

    @Test
    func routeProvidedWithStackFalse_present_return_sheetNotInStack() {
      splitRouter.present(TestRoute.home, withStack: false)

      #expect(splitRouter.sheet?.inStack == false)
    }

    @Test
    func routeProvided_present_return_coverUnchanged() {
      splitRouter.present(TestRoute.home)

      #expect(splitRouter.cover == nil)
    }
  }

  @MainActor
  struct Cover: SplitRouterTestSuite {
    let parentRouter: Router
    let splitRouter: SplitRouter

    @Test
    func routeProvided_cover_return_coverSet() {
      splitRouter.cover(TestRoute.home)

      #expect((splitRouter.cover?.wrapped as? TestRoute) == .home)
    }

    @Test
    func routeProvided_cover_return_sheetUnchanged() {
      splitRouter.cover(TestRoute.home)

      #expect(splitRouter.sheet == nil)
    }
  }

  @MainActor
  struct AddContext: SplitRouterTestSuite {
    let parentRouter: Router
    let splitRouter: SplitRouter

    @Test
    func contextRegistered_context_return_observerCalled() {
      var received: StringContext?
      splitRouter.add(context: StringContext.self) { received = $0 }

      splitRouter.context(StringContext(value: "test"))

      #expect(received?.value == "test")
    }

    @Test
    func noObserverRegistered_context_return_noCrash() {
      splitRouter.context(StringContext(value: "no-observer"))
    }

    @Test
    func differentContextType_context_return_observerNotCalled() {
      var received: StringContext?
      splitRouter.add(context: StringContext.self) { received = $0 }

      splitRouter.context(IntContext(value: 42))

      #expect(received == nil)
    }
  }

  @MainActor
  struct RemoveContext: SplitRouterTestSuite {
    let parentRouter: Router
    let splitRouter: SplitRouter

    @Test
    func observerRegistered_removeContext_return_observerNotCalledAfterRemoval() {
      var received: StringContext?
      splitRouter.add(context: StringContext.self) { received = $0 }

      splitRouter.remove(context: StringContext.self)
      splitRouter.context(StringContext(value: "after-remove"))

      #expect(received == nil)
    }

    @Test
    func noObserver_removeContext_return_noCrash() {
      splitRouter.remove(context: StringContext.self)
    }
  }

  @MainActor
  struct ContextPropagation: SplitRouterTestSuite {
    let parentRouter: Router
    let splitRouter: SplitRouter

    @Test
    func observerOnParent_contextFromSplitRouter_return_parentObserverCalled() {
      var received: StringContext?
      parentRouter.add(context: StringContext.self) { received = $0 }

      splitRouter.context(StringContext(value: "propagated"))

      #expect(received?.value == "propagated")
    }
  }
}
