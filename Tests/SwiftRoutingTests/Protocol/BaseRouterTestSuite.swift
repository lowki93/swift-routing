@testable import SwiftRouting

@MainActor
protocol BaseRouterTestSuite {
  var baseRouter: BaseRouter { get }
  init(baseRouter: BaseRouter)
}

@MainActor
extension BaseRouterTestSuite {
  init() {
    self.init(baseRouter: BaseRouter(configuration: Configuration()))
  }
}
