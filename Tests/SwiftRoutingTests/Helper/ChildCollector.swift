@testable import SwiftRouting

/// Retains routers created concurrently across multiple tasks so they don't deinit (and
/// remove themselves from their parent) before a test can assert on the parent's state.
actor ChildCollector {
  private var routers: [Router] = []

  func add(_ router: Router) {
    routers.append(router)
  }

  var count: Int { routers.count }
}
