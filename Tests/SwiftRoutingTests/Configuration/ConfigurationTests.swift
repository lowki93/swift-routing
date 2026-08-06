import Testing
import Combine
@testable import SwiftRouting

@MainActor
struct ConfigurationTests {
  @MainActor
  struct Events {
    /// `log(_:)` defers `events.send()` to the next run loop tick, so events queued by
    /// router *creation* (before a test subscribes) can still land after subscription.
    /// Call this after creating routers and before asserting on a specific action, so
    /// only that action's event is counted.
    private func flushPendingEvents() async throws {
      try await Task.sleep(for: .milliseconds(50))
    }

    @Test
    func eventLogged_events_return_fired() async throws {
      var cancellables = Set<AnyCancellable>()
      let router = Router(configuration: Configuration())
      try await flushPendingEvents()
      var fireCount = 0
      router.configuration.events
        .sink { fireCount += 1 }
        .store(in: &cancellables)

      router.push(TestRoute.home)
      try await flushPendingEvents()

      #expect(fireCount == 1)
    }

    @Test
    func eventLoggedOnChild_events_return_receivedOnSharedConfiguration() async throws {
      var cancellables = Set<AnyCancellable>()
      let parentRouter = Router(configuration: Configuration())
      let childRouter = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: parentRouter
      )
      try await flushPendingEvents()
      var fireCount = 0
      // Subscribing on the parent's configuration still receives events logged by the
      // child, since `events` is shared by reference across the whole router hierarchy.
      parentRouter.configuration.events
        .sink { fireCount += 1 }
        .store(in: &cancellables)

      childRouter.push(TestRoute.settings)
      try await flushPendingEvents()

      #expect(fireCount == 1)
    }

    @Test
    func loggerClosureStillCalled_events_return_bothLoggerAndEventsReceiveIt() async throws {
      var cancellables = Set<AnyCancellable>()
      let loggerSpy = LoggerSpy(storesConfiguration: false)
      let router = Router(configuration: Configuration(loggerSpy: loggerSpy))
      try await flushPendingEvents()
      var fireCount = 0
      router.configuration.events
        .sink { fireCount += 1 }
        .store(in: &cancellables)
      loggerSpy.clearReceivedMessages()

      router.push(TestRoute.home)
      try await flushPendingEvents()

      #expect(loggerSpy.receivedRouterId == router.id)
      #expect(fireCount == 1)
    }

    @Test
    func onAppearLogged_events_return_notFired() async throws {
      var cancellables = Set<AnyCancellable>()
      let router = Router(configuration: Configuration())
      try await flushPendingEvents()
      var fireCount = 0
      router.configuration.events
        .sink { fireCount += 1 }
        .store(in: &cancellables)

      router.log(.onAppear(TestRoute.home))
      try await flushPendingEvents()

      #expect(fireCount == 0)
    }

    @Test
    func onDisappearLogged_events_return_notFired() async throws {
      var cancellables = Set<AnyCancellable>()
      let router = Router(configuration: Configuration())
      try await flushPendingEvents()
      var fireCount = 0
      router.configuration.events
        .sink { fireCount += 1 }
        .store(in: &cancellables)

      router.log(.onDisappear(TestRoute.home))
      try await flushPendingEvents()

      #expect(fireCount == 0)
    }

    @Test
    func routerDeallocated_events_return_doesNotDelayDeinit() {
      // Regression test: `events` must not capture `router`/`self` anywhere reachable from
      // `log(_:)`'s deferred Task, or every router's deinit would be delayed until that
      // Task runs (or, for `.delete` specifically, crash with "deallocated with non-zero
      // retain count" since that Task would resurrect a router mid-deinit).
      let loggerSpy = LoggerSpy(storesConfiguration: false)
      var router: BaseRouter? = BaseRouter(configuration: Configuration(loggerSpy: loggerSpy), root: AnyRoute(wrapped: DefaultRoute.main))
      let routerId = router?.id

      router = nil

      #expect(router == nil)
      #expect(loggerSpy.receivedRouterId == routerId)
      assertLogMessageKind(loggerSpy, is: .delete)
    }

    @Test
    func parentAndChildDeinitAroundSameTime_events_return_noCrash() async throws {
      // Regression test: sending on a PassthroughSubject shared across a parent/child
      // router hierarchy, synchronously from `deinit`, could reenter the same subject and
      // crash Combine when both routers are released around the same time. `log(_:)`
      // defers the send to the next run loop tick specifically to avoid this.
      var cancellables = Set<AnyCancellable>()
      var parentRouter: Router? = Router(configuration: Configuration())
      var childRouter: Router? = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .presented("sheet"),
        parent: parentRouter!
      )
      parentRouter?.configuration.events
        .sink { _ in }
        .store(in: &cancellables)

      childRouter = nil
      parentRouter = nil
      try await flushPendingEvents()

      #expect(childRouter == nil)
      #expect(parentRouter == nil)
    }
  }
}
