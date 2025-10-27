//
//  RouterContextModifier.swift
//  swift-routing
//
//  Created by Kevin Budain on 23/04/2025.
//

import SwiftUI

public struct RouterContextModifier<R: RouteContext>: ViewModifier {

  @State private var first = true
  @Environment(\.router) private var router
  let object: R.Type
  let perform: (R) -> Void

  public func body(content: Content) -> some View {
    content
      .onAppear {
        guard first else { return }
        first = false
        guard let context = RouterContext(
          router: router,
          routerContext: object,
          action: { [perform] in
            guard let value = $0 as? R else { return }
            perform(value)
          }
        ) else { return }
        print("Insert ", context)
        router.contexts.insert(context)
      }
  }
}

public extension View {
  func routerContext<R: RouteContext>(_ object: R.Type, perform: @escaping (R) -> Void) -> some View {
    self.modifier(RouterContextModifier(object: object, perform: perform))
  }
}
