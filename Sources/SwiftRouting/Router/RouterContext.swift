//
//  RouterContext.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/3/25.
//

struct RouterContext: Hashable {
  private let router: Router
  private let route: any Route
  let pathCount: Int
  let routerContext: any RouteContext.Type
  private let termination: (any RouteContext) -> Void

  init?(
    router: Router,
    routerContext: any RouteContext.Type,
    termination: @escaping (any RouteContext) -> Void
  ) {
    guard let route = router.currentRoute else { return nil }
    self.router = router
    self.route = route.wrapped
    self.pathCount = router.path.count
    self.routerContext = routerContext
    self.termination = termination
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(router.id)
    hasher.combine(route.hashValue)
    hasher.combine("\(routerContext)")
  }

  @MainActor func execute(_ object: some RouteContext) {
    termination(object)
    router.log(.terminate, verbosity: .debug, message: "termination")
  }

  static func == (lhs: RouterContext, rhs: RouterContext) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}

extension Set where Element == RouterContext {
  func first<T: RouteContext>(for termination: T.Type) -> Self.Element? {
    first(where: { $0.routerContext == termination })
  }

  func all<T: RouteContext>(for termination: T.Type) -> Self {
    filter { $0.routerContext == termination }
  }
}
