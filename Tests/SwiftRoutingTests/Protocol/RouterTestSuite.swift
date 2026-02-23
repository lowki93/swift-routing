import SwiftRouting

@MainActor
protocol RouterTestSuite {
  var router: Router { get }
  init(router: Router)
}

@MainActor
extension RouterTestSuite {
  init() {
    self.init(
      router: Router(configuration: Configuration())
    )
  }
}
