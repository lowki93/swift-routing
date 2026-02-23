@testable import SwiftRouting

@MainActor
protocol TabRouterTestSuite {
  var parentRouter: Router { get }
  var tabRouter: TabRouter { get }
  init(parentRouter: Router, tabRouter: TabRouter)
}

@MainActor
extension TabRouterTestSuite {
  init() {
    let parentRouter = Router(
      configuration: Configuration(logger: nil, shouldCrashOnRouteNotFound: false)
    )
    let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)
    self.init(parentRouter: parentRouter, tabRouter: tabRouter)
  }
}
