//
//  ProfileViewModelTests.swift
//  SwiftRoutingDemoTests
//

import SwiftRouting
import SwiftRoutingTestSupport
import Testing

@testable import SwiftRoutingDemo

// Testing.md "Strategy 2: Test ViewModel Navigation" -- inject a TabRouterSpy as the
// `any TabRouterModel` and assert on the routes and tabs the ViewModel targeted.
@MainActor
struct ProfileViewModelTests {
  @MainActor
  struct PresentSearch {
    @Test
    func presentSearch_return_presentedSearchInCurrentTab() {
      let spy = TabRouterSpy(root: AppRoute.home(name: "Test"))
      let viewModel = ProfileViewModel(tabRouter: spy)

      viewModel.presentSearch()

      #expect(spy.presentedRoutes.count == 1)
      #expect((spy.presentedRoutes.first?.route as? AppRoute) == .search)
      #expect(spy.presentedRoutes.first?.tab == nil)
    }
  }

  @MainActor
  struct CoverAbout {
    @Test
    func coverAbout_return_coveredAboutInCurrentTab() {
      let spy = TabRouterSpy(root: AppRoute.home(name: "Test"))
      let viewModel = ProfileViewModel(tabRouter: spy)

      viewModel.coverAbout()

      #expect(spy.coveredRoutes.count == 1)
      #expect((spy.coveredRoutes.first?.route as? AppRoute) == .about)
      #expect(spy.coveredRoutes.first?.tab == nil)
    }
  }

  @MainActor
  struct PresentSearchInNotifications {
    @Test
    func presentSearchInNotifications_return_presentedSearchInNotificationsTab() {
      let spy = TabRouterSpy(root: AppRoute.home(name: "Test"))
      let viewModel = ProfileViewModel(tabRouter: spy)

      viewModel.presentSearchInNotifications()

      #expect(spy.presentedRoutes.count == 1)
      #expect((spy.presentedRoutes.first?.route as? AppRoute) == .search)
      #expect((spy.presentedRoutes.first?.tab as? HomeTab) == .notifications)
    }
  }

  @MainActor
  struct ResetHomeTab {
    @Test
    func resetHomeTab_return_poppedToRootInHomeTab() {
      let spy = TabRouterSpy(root: AppRoute.home(name: "Test"))
      let viewModel = ProfileViewModel(tabRouter: spy)

      viewModel.resetHomeTab()

      #expect(spy.popToRootTabs.count == 1)
      #expect((spy.popToRootTabs.first.flatMap { $0 } as? HomeTab) == .home)
    }

    @Test
    func resetHomeTab_return_noTabChange() {
      let spy = TabRouterSpy(root: AppRoute.home(name: "Test"))
      let viewModel = ProfileViewModel(tabRouter: spy)

      viewModel.resetHomeTab()

      #expect(spy.changedTabs.isEmpty)
    }
  }

  @MainActor
  struct WithoutTabRouter {
    @Test
    func presentSearch_return_noCrash() {
      let viewModel = ProfileViewModel(tabRouter: nil)

      viewModel.presentSearch()
    }
  }
}
