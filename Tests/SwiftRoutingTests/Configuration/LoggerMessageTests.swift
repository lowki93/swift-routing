import Testing
@testable import SwiftRouting

@MainActor
struct LoggerMessageTests {
  @MainActor
  struct ShouldTriggerEvent {
    @Test
    func onAppear_shouldTriggerEvent_return_false() {
      #expect(LoggerMessage.onAppear(TestRoute.home).shouldTriggerEvent == false)
    }

    @Test
    func onDisappear_shouldTriggerEvent_return_false() {
      #expect(LoggerMessage.onDisappear(TestRoute.home).shouldTriggerEvent == false)
    }

    @Test
    func error_shouldTriggerEvent_return_false() {
      #expect(LoggerMessage.error(.routeNotFound(route: TestRoute.home, in: TestRouteDestination.self)).shouldTriggerEvent == false)
    }

    @Test
    func create_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.create(from: nil, nil).shouldTriggerEvent)
    }

    @Test
    func delete_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.delete.shouldTriggerEvent)
    }

    @Test
    func navigation_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.navigation(from: TestRoute.home, to: TestRoute.settings, type: .push).shouldTriggerEvent)
    }
  }

  @MainActor
  struct ActionShouldTriggerEvent {
    let router: Router

    init() {
      self.router = Router(configuration: .default)
    }

    @Test
    func popToRoot_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.Action.popToRoot.shouldTriggerEvent)
    }

    @Test
    func close_shouldTriggerEvent_return_false() {
      #expect(LoggerMessage.Action.close.shouldTriggerEvent == false)
    }

    @Test
    func back_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.Action.back().shouldTriggerEvent)
    }

    @Test
    func closeChildren_shouldTriggerEvent_return_false() {
      #expect(LoggerMessage.Action.closeChildren(router).shouldTriggerEvent == false)
    }

    @Test
    func changeTab_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.Action.changeTab(TestTabRoute.home).shouldTriggerEvent)
    }
  }

  @MainActor
  struct ContextShouldTriggerEvent {
    @Test
    func add_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.Context.add(TestRoute.home, context: StringContext.self).shouldTriggerEvent)
    }

    @Test
    func remove_shouldTriggerEvent_return_true() {
      #expect(LoggerMessage.Context.remove(TestRoute.home, context: StringContext.self).shouldTriggerEvent)
    }

    @Test
    func execute_shouldTriggerEvent_return_false() {
      #expect(LoggerMessage.Context.execute(StringContext(value: "test"), from: TestRoute.home).shouldTriggerEvent == false)
    }
  }
}
