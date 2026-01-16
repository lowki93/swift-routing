//
//  RouterContextModifier.swift
//  swift-routing
//
//  Created by Kevin Budain on 23/04/2025.
//

import SwiftUI

public struct RouterContextModifier<R: RouteContext>: ViewModifier {

  @Environment(\.router) private var router
  @State private var firstTime: Bool = false
  let object: R.Type
  let perform: (R) -> Void

  public func body(content: Content) -> some View {
    content
      .onAppear {
        guard !firstTime else { return }
        firstTime = true

        router.add(context: object, perform: perform)
      }
  }
}

public extension View {
  /// > **Warning:**
  /// If you reference a class instance (e.g. a view model) inside the `perform` closure, capture it [weak] or [unowned] to prevent memory leaks.
  ///
  /// Example:
  /// ```swift
  /// .routerContext(Int.self) { [weak model] context in
  ///   model?.update(int: context)
  /// }
  /// ```
  func routerContext<R: RouteContext>(_ object: R.Type, perform: @escaping (R) -> Void) -> some View {
    self.modifier(RouterContextModifier(object: object, perform: perform))
  }
}
