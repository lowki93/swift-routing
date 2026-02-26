//
//  RouterContext.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/3/25.
//

import Foundation

struct RouterContext: Hashable {
  let route: any Route
  let pathCount: Int
  let routerContext: any RouteContext.Type
  private weak var router: Router?
  private let id: UUID
  private let action: (any RouteContext) -> Void

  init(router: Router, routerContext: any RouteContext.Type, action: @escaping (any RouteContext) -> Void) {
    self.id = router.id
    self.route = router.currentRoute.wrapped
    self.pathCount = router.path.count
    self.routerContext = routerContext
    self.action = action
    self.router = router
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(route.hashValue)
    hasher.combine("\(routerContext)")
  }

  @MainActor func execute(_ object: some RouteContext) {
    router?.log(.context(.execute(object, from: route)))
    action(object)
  }

  static func == (lhs: RouterContext, rhs: RouterContext) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}

extension Set where Element == RouterContext {
  func first<T: RouteContext>(for termination: T.Type, currentRoute: any Route) -> Self.Element? {
    first(where: { $0.routerContext == termination && !$0.route.isSame(as: currentRoute) })
  }

  func all<T: RouteContext>(for termination: T.Type) -> Self {
    filter { $0.routerContext == termination }
  }

  func all<T: RouteContext>(for termination: T.Type, currentRoute: any Route) -> Self {
    filter {
      $0.routerContext == termination
      && $0.route.isSame(as: currentRoute)
    }
  }

  func all(for routes: [any Route]) -> Self {
    filter { context in
      routes.contains { route in
        context.route.isSame(as: route)
      }
    }
  }
}
