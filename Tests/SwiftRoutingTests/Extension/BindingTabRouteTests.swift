import Combine
import SwiftUI
import Testing
@testable import SwiftRouting

@MainActor
struct BindingTabRouteTests {

  @MainActor
  struct PopToRootOnReselection {
    @Test
    func sameTabReselected_tabToRoot_popsMatchingRouterToRoot() {
      let parentRouter = Router(configuration: Configuration())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)
      let homeRouter = attachRouter(in: tabRouter, tab: .home, root: .home)
      homeRouter.push(TestRoute.details(id: "42"))
      var currentTab = TestTabRoute.home
      let binding = Binding.tabToRoot(for: Binding(get: { currentTab }, set: { currentTab = $0 }), in: tabRouter)

      binding.wrappedValue = .home

      #expect(homeRouter.path.isEmpty)
    }

    @Test
    func sameTabReselected_tabToRoot_sendsTabReselectedEvent() {
      let parentRouter = Router(configuration: Configuration())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)
      var currentTab = TestTabRoute.home
      let binding = Binding.tabToRoot(for: Binding(get: { currentTab }, set: { currentTab = $0 }), in: tabRouter)
      var receivedTab: AnyTabRoute?
      let cancellable = tabRouter.tabReselected.sink { receivedTab = $0 }

      binding.wrappedValue = .home

      #expect((receivedTab?.wrapped as? TestTabRoute) == .home)
      cancellable.cancel()
    }
  }

  @MainActor
  struct NoPopWhenTabNotActive {
    @Test
    func differentTabSelected_tabToRoot_doesNotPopTargetRouter() {
      let parentRouter = Router(configuration: Configuration())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)
      let settingsRouter = attachRouter(in: tabRouter, tab: .settings, root: .settings)
      settingsRouter.push(TestRoute.details(id: "42"))
      var currentTab = TestTabRoute.home
      let binding = Binding.tabToRoot(for: Binding(get: { currentTab }, set: { currentTab = $0 }), in: tabRouter)

      binding.wrappedValue = .settings

      #expect(settingsRouter.path.count == 1)
    }

    @Test
    func differentTabSelected_tabToRoot_doesNotSendTabReselectedEvent() {
      let parentRouter = Router(configuration: Configuration())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)
      var currentTab = TestTabRoute.home
      let binding = Binding.tabToRoot(for: Binding(get: { currentTab }, set: { currentTab = $0 }), in: tabRouter)
      var receivedTab: AnyTabRoute?
      let cancellable = tabRouter.tabReselected.sink { receivedTab = $0 }

      binding.wrappedValue = .settings

      #expect(receivedTab == nil)
      cancellable.cancel()
    }
  }

  @MainActor
  struct BindingSync {
    @Test
    func differentTabSelected_tabToRoot_updatesLocalBindingValue() {
      let parentRouter = Router(configuration: Configuration())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)
      var currentTab = TestTabRoute.home
      let binding = Binding.tabToRoot(for: Binding(get: { currentTab }, set: { currentTab = $0 }), in: tabRouter)

      binding.wrappedValue = .settings

      #expect(currentTab == .settings)
    }

    @Test
    func differentTabSelected_tabToRoot_syncsTabRouterTab() {
      let parentRouter = Router(configuration: Configuration())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)
      var currentTab = TestTabRoute.home
      let binding = Binding.tabToRoot(for: Binding(get: { currentTab }, set: { currentTab = $0 }), in: tabRouter)

      binding.wrappedValue = .settings

      #expect((tabRouter.tab.wrapped as? TestTabRoute) == .settings)
    }

    @Test
    func differentTabSelected_tabToRoot_withoutTabRouterParent_updatesLocalBindingOnly() {
      let parentRouter = Router(configuration: Configuration())
      var currentTab = TestTabRoute.home
      let binding = Binding.tabToRoot(for: Binding(get: { currentTab }, set: { currentTab = $0 }), in: parentRouter)

      binding.wrappedValue = .settings

      #expect(currentTab == .settings)
    }
  }
}

@MainActor
private func attachRouter(
  in tabRouter: TabRouter,
  tab: TestTabRoute,
  root: TestRoute
) -> Router {
  Router(
    root: AnyRoute(wrapped: root),
    type: tab.type,
    parent: tabRouter
  )
}
