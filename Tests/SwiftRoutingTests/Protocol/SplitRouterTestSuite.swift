@testable import SwiftRouting

@MainActor
protocol SplitRouterTestSuite {
  var parentRouter: Router { get }
  var splitRouter: Router { get }
  init(parentRouter: Router, splitRouter: Router)
}

@MainActor
extension SplitRouterTestSuite {
  init() {
    let parentRouter = Router(configuration: Configuration())
    let splitRouter = Router(root: AnyRoute(wrapped: DefaultRoute.main), type: .split(DefaultRoute.main.name, hasContentColumn: false), parent: parentRouter)
    self.init(parentRouter: parentRouter, splitRouter: splitRouter)
  }
}
