//
//  RouterContext.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/3/25.
//

public struct RouterContext {
  let router: Router
  let pathCount: Int

  @MainActor public func onTerminate<R: TerminationRoute>(_ object: R.Type, perform: @escaping (R) -> Void)  {
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
        router.back(to: pathCount)
      }
    }
  }
}
