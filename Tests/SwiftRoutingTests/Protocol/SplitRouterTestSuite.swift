@testable import SwiftRouting

@MainActor
protocol SplitRouterTestSuite {
  var parentRouter: Router { get }
  var splitRouter: SplitRouter2 { get }
  init(parentRouter: Router, splitRouter: SplitRouter2)
}

@MainActor
extension SplitRouterTestSuite {
  init() {
    let parentRouter = Router(configuration: Configuration())
    let splitRouter = SplitRouter2(root: AnyRoute(wrapped: DefaultRoute.main), hasContentColumn: false, parent: parentRouter)
    self.init(parentRouter: parentRouter, splitRouter: splitRouter)
  }
}
