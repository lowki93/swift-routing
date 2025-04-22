//
//  LifecycleModifier.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

struct LifecycleModifier: ViewModifier {

  @Environment(\.router) private var router
  let route: any Route
  let logAction: LoggerAction = .viewLifecycle

  func body(content: Content) -> some View {
    content
      .onAppear { router.log(logAction, metadata: ["OnAppear": route]) }
      .onDisappear { router.log(logAction, metadata: ["Disappear": route]) }
  }
}

public struct RouterContextModifier<R: TerminationRoute>: ViewModifier {

  @Environment(\.router) private var router
  let object: R.Type
  let perform: (R) -> Void

  public func body(content: Content) -> some View {
    content
      .onAppear {
        guard let lastRoute = router.lastRoute else { return }
        print("==== Context 2")
        router.contexts.insert(RouterContext2(
          router: router,
          route: lastRoute.wrapped,
          terminationRoute: object,
          onTerminate: { value, router in
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
              print("=-=-= back: ", self.router.path.count)
              router.back(to: self.router.path.count)
            }
          }
        ))
      }
  }
}

public extension View {
  func routerContext<R: TerminationRoute>(_ object: R.Type, perform: @escaping (R) -> Void) -> some View {
    self.modifier(RouterContextModifier(object: object, perform: perform))
  }
}
