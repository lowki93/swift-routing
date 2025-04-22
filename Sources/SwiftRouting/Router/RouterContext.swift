//
//  RouterContext.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/3/25.
//

public struct RouterContext : Sendable {
  let router: Router
  let pathCount: Int

  @MainActor public func onTerminate<R: TerminationRoute>(_ object: R.Type, perform: @escaping (R) -> Void)  {
    print("==== Context")
    router.onTerminate = { value, router in
      guard let value = value as? R else {
        self.router
          .log(
            .terminate,
            verbosity: .error,
            message: "onTerminate",
            metadata: ["Value": "\(type(of: value))", "Object" :"\(R.self)"]
          )
        return
      }
      perform(value)

      if router.isPresented {
        router.close()
      } else {
        print("=== back: ", pathCount)
        router.back(to: pathCount)
      }
    }
  }
}

struct RouterContext2: Hashable {
  let router: Router
  let route: any Route
  let terminationRoute: any TerminationRoute.Type
  let onTerminate: (any TerminationRoute, Router) -> Void

  func hash(into hasher: inout Hasher) {
    hasher.combine(router.id)
    hasher.combine(route.hashValue)
    // TODO: explication
    hasher.combine("\(terminationRoute)")
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
