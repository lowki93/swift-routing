@testable import SwiftRouting

@MainActor
protocol SplitRouterTestSuite {
  var parentRouter: Router { get }
  var splitRouter: SplitRouter { get }
  init(parentRouter: Router, splitRouter: SplitRouter)
}

@MainActor
extension SplitRouterTestSuite {
  init() {
    let parentRouter = Router(configuration: Configuration())
    let splitRouter = SplitRouter(parent: parentRouter)
    self.init(parentRouter: parentRouter, splitRouter: splitRouter)
  }
}
