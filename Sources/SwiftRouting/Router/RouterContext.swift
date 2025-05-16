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
  let routeTermination: any RouteTermination.Type
  private let termination: (any RouteTermination) -> Void

  init?(
    router: Router,
    routeTermination: any RouteTermination.Type,
    termination: @escaping (any RouteTermination) -> Void
  ) {
    guard let route = router.lastRoute else { return nil }
    self.router = router
    self.route = route.wrapped
    self.pathCount = router.path.count
    self.routeTermination = routeTermination
    self.termination = termination
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(router.id)
    hasher.combine(route.hashValue)
    hasher.combine("\(routeTermination)")
  }

  @MainActor func execute(_ object: some RouteTermination) {
    termination(object)
    router.log(.terminate, verbosity: .debug, message: "termination")
  }

  static func == (lhs: RouterContext, rhs: RouterContext) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}

extension Set where Element == RouterContext{
  func first<T: RouteTermination>(for termination: T.Type) -> Self.Element? {
    first(where: { $0.routeTermination == termination })
  }
}
