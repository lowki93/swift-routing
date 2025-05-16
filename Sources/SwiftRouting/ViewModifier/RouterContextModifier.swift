//
//  RouterContextModifier.swift
//  swift-routing
//
//  Created by Kevin Budain on 23/04/2025.
//

import SwiftUI

public struct RouterContextModifier<R: RouteTermination>: ViewModifier {

  @Environment(\.router) private var router
  let object: R.Type
  let perform: (R) -> Void

  public func body(content: Content) -> some View {
    content
      .onAppear {
        guard let context = RouterContext(
          router: router,
          routeTermination: object,
          termination: {
            guard let value = $0 as? R else { return }
            perform(value)
          }
        ) else { return }
        router.contexts.insert(context)
      }
  }
}

public extension View {
  func routerContext<R: RouteTermination>(_ object: R.Type, perform: @escaping (R) -> Void) -> some View {
    self.modifier(RouterContextModifier(object: object, perform: perform))
  }
}
