import Testing
import SwiftRouting
@testable import SwiftRoutingTestSupport

@MainActor
struct RouterSpyTests {
  struct Push {
    @Test
    func push_return_recordedRouteAndCurrentRouteUpdated() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.push(FixtureRoute.details(id: "42"))

      #expect(spy.pushedRoutes.count == 1)
      #expect((spy.pushedRoutes.first as? FixtureRoute) == .details(id: "42"))
      #expect((spy.currentRoute.wrapped as? FixtureRoute) == .details(id: "42"))
      #expect(spy.pathCount == 1)
    }
  }

  struct Present {
    @Test
    func present_return_recordedRouteAndWithStack() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.present(FixtureRoute.details(id: "sheet"), withStack: false)

      #expect(spy.presentedRoutes.count == 1)
      #expect((spy.presentedRoutes.first?.route as? FixtureRoute) == .details(id: "sheet"))
      #expect(spy.presentedRoutes.first?.withStack == false)
    }
  }

  struct Cover {
    @Test
    func cover_return_recordedRoute() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.cover(FixtureRoute.details(id: "cover"))

      #expect((spy.coveredRoutes.first as? FixtureRoute) == .details(id: "cover"))
    }
  }

  struct UpdateRoot {
    @Test
    func updateRoot_return_rootAndCurrentRouteReplaced() {
      let spy = RouterSpy(root: FixtureRoute.home)
      spy.push(FixtureRoute.details(id: "42"))

      spy.update(root: FixtureRoute.details(id: "new-root"))

      #expect((spy.root.wrapped as? FixtureRoute) == .details(id: "new-root"))
      #expect((spy.currentRoute.wrapped as? FixtureRoute) == .details(id: "new-root"))
      #expect(spy.pathCount == 0)
      #expect((spy.updatedRoots.first as? FixtureRoute) == .details(id: "new-root"))
    }
  }

  struct PopToRootBackClose {
    @Test
    func popToRoot_return_currentRouteResetAndCallCounted() {
      let spy = RouterSpy(root: FixtureRoute.home)
      spy.push(FixtureRoute.details(id: "42"))

      spy.popToRoot()

      #expect(spy.popToRootCallCount == 1)
      #expect((spy.currentRoute.wrapped as? FixtureRoute) == .home)
      #expect(spy.pathCount == 0)
    }

    @Test
    func back_return_pathCountDecrementedAndCallCounted() {
      let spy = RouterSpy(root: FixtureRoute.home)
      spy.push(FixtureRoute.details(id: "42"))

      spy.back()

      #expect(spy.backCallCount == 1)
      #expect(spy.pathCount == 0)
    }

    @Test
    func close_return_callCounted() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.close()
      spy.close()

      #expect(spy.closeCallCount == 2)
    }

    @Test
    func closeChildren_return_callCounted() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.closeChildren()

      #expect(spy.closeChildrenCallCount == 1)
    }
  }

  struct Context {
    @Test
    func addContext_context_return_handlerInvoked() {
      let spy = RouterSpy(root: FixtureRoute.home)
      var received: FixtureContext?

      spy.add(context: FixtureContext.self) { context in
        received = context
      }
      spy.context(FixtureContext(value: "42"))

      #expect(spy.addedContextTypes.count == 1)
      #expect(spy.dispatchedContexts.count == 1)
      #expect(received == FixtureContext(value: "42"))
    }

    @Test
    func removeContext_context_return_handlerNotInvoked() {
      let spy = RouterSpy(root: FixtureRoute.home)
      var received: FixtureContext?
      spy.add(context: FixtureContext.self) { context in
        received = context
      }

      spy.remove(context: FixtureContext.self)
      spy.context(FixtureContext(value: "42"))

      #expect(spy.removedContextTypes.count == 1)
      #expect(received == nil)
    }

    @Test
    func terminate_return_recordedContext() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.terminate(FixtureContext(value: "42"))

      #expect(spy.terminatedContexts.count == 1)
      #expect(spy.terminatedContexts.first as? FixtureContext == FixtureContext(value: "42"))
    }

    @Test
    func noObserverRegistered_canTerminate_return_false() {
      let spy = RouterSpy(root: FixtureRoute.home)

      #expect(spy.canTerminate(FixtureContext.self) == false)
    }

    @Test
    func observerRegistered_canTerminate_return_true() {
      let spy = RouterSpy(root: FixtureRoute.home)
      spy.add(context: FixtureContext.self) { _ in }

      #expect(spy.canTerminate(FixtureContext.self) == true)
    }

    @Test
    func observerRemoved_canTerminate_return_false() {
      let spy = RouterSpy(root: FixtureRoute.home)
      spy.add(context: FixtureContext.self) { _ in }
      spy.remove(context: FixtureContext.self)

      #expect(spy.canTerminate(FixtureContext.self) == false)
    }
  }

  struct Split {
    @Test
    func selectDetail_return_recordedAndBindingUpdated() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.select(detail: "player-1")

      #expect(spy.detailSelections == [AnyHashable("player-1")])
      #expect(spy.detailSelection == AnyHashable("player-1"))
      #expect(spy.detailBinding(as: String.self).wrappedValue == "player-1")
    }

    @Test
    func selectContent_return_recordedAndBindingUpdated() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.select(content: "type-1")

      #expect(spy.contentSelections == [AnyHashable("type-1")])
      #expect(spy.contentSelection == AnyHashable("type-1"))
      #expect(spy.contentBinding(as: String.self).wrappedValue == "type-1")
    }

    @Test
    func detailBindingSet_return_selectRecorded() {
      let spy = RouterSpy(root: FixtureRoute.home)

      spy.detailBinding(as: String.self).wrappedValue = "from-binding"

      #expect(spy.detailSelection == AnyHashable("from-binding"))
    }
  }

  @MainActor
  struct Unsupported {
    @Test
    func hierarchyLookups_return_nilOrNoOp() {
      let spy = RouterSpy(root: FixtureRoute.home)

      #expect(spy.tabRouter == nil)
      #expect(spy.deepestRouter() == nil)
      spy.clearChildren()
    }
  }
}
