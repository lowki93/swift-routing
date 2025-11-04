//
//  RouterContextModifier.swift
//  swift-routing
//
//  Created by Kevin Budain on 23/04/2025.
//

import SwiftUI

public struct RouterContextModifier<R: RouteContext>: ViewModifier {

  @Environment(\.router) private var router
  let object: R.Type
  let perform: (R) -> Void

  public func body(content: Content) -> some View {
    content
      .onAppear {
        let (inserted, _) = router.contexts.insert(
          RouterContext(
            router: router,
            routerContext: object,
            action: { [perform] in
              guard let value = $0 as? R else { return }
              perform(value)
            }
          )
        )
        if inserted {
          router.log(.context(.add(router.currentRoute.wrapped, context: object)))
        }
      }
  }
}

public extension View {
  func routerContext<R: RouteContext>(_ object: R.Type, perform: @escaping (R) -> Void) -> some View {
    self.modifier(RouterContextModifier(object: object, perform: perform))
  }
}
