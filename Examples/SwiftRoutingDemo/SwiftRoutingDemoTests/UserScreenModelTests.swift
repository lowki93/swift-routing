//
//  UserScreenModelTests.swift
//  SwiftRoutingDemoTests
//

import SwiftRouting
import SwiftRoutingTestSupport
import Testing

@testable import SwiftRoutingDemo

// Testing.md "Strategy 1: RouterSpy" -- inject a RouterSpy as the `any RouterModel`
// and assert on what the ViewModel asked the router to do, with no UI involved.
@MainActor
struct UserScreenModelTests {
  @MainActor
  struct PushBen {
    @Test
    func pushBen_return_pushedUserBenRoute() {
      let spy = RouterSpy(root: AppRoute.home(name: "Test"))
      let model = UserScreenModel(name: "Me", router: spy)

      model.pushBen()

      #expect(spy.pushedRoutes.count == 1)
      #expect((spy.pushedRoutes.first as? AppRoute) == .user(name: "Ben"))
    }
  }

  @MainActor
  struct Pop {
    @Test
    func pop_return_popCalledOnce() {
      let spy = RouterSpy(root: AppRoute.home(name: "Test"))
      let model = UserScreenModel(name: "Me", router: spy)

      model.pop()

      #expect(spy.popCallCount == 1)
    }
  }

  @MainActor
  struct PopToRoot {
    @Test
    func popToRoot_return_popToRootCalledOnce() {
      let spy = RouterSpy(root: AppRoute.home(name: "Test"))
      let model = UserScreenModel(name: "Me", router: spy)

      model.popToRoot()

      #expect(spy.popToRootCallCount == 1)
    }
  }
}
