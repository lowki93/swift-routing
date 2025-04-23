//
//  RouterContext.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/3/25.
//

struct RouterContext2: Hashable {
  private var terminationRouteString: String {
    "\(terminationRoute)"
  }
  private let router: Router
  private let route: any Route
  let pathCount: Int
  let terminationRoute: any TerminationRoute.Type
  private let termination: (any TerminationRoute) -> Void

  init?(
    router: Router,
    terminationRoute: any TerminationRoute.Type,
    termination: @escaping (any TerminationRoute) -> Void
  ) {
    guard let route = router.lastRoute else { return nil }
    self.router = router
    self.route = route.wrapped
    self.pathCount = router.path.count
    self.terminationRoute = terminationRoute
    self.termination = termination
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(router.id)
    hasher.combine(route.hashValue)
    hasher.combine(terminationRouteString)
  }

  @MainActor func exexute(_ object: some TerminationRoute) {
    termination(object)
    router.log(.terminate, verbosity: .debug, message: "termination")
  }

  static func == (lhs: RouterContext2, rhs: RouterContext2) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}

extension Set where Element == RouterContext2{
  func first<T: TerminationRoute>(for termination: T.Type) -> Self.Element? {
    first(where: { $0.terminationRoute == termination })
  }
}
