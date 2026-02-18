//
//  RouterContextModifier.swift
//  swift-routing
//
//  Created by Kevin Budain on 23/04/2025.
//

import SwiftUI

/// A view modifier that registers a context observer on the current router.
///
/// `RouterContextModifier` automatically registers a ``RouteContext`` observer
/// when the view appears, allowing you to receive data from child routes
/// when they call `context(_:)` or `terminate(_:)`.
///
/// ## Overview
///
/// Use this modifier (via the `routerContext(_:perform:)` view extension) to listen
/// for context events without manually calling `router.add(context:perform:)`.
///
/// ```swift
/// struct ParentView: View {
///   @State private var selectedItem: Item?
///
///   var body: some View {
///     ContentView()
///       .routerContext(ItemSelectionContext.self) { [weak self] context in
///         self?.selectedItem = context.item
///       }
///   }
/// }
/// ```
///
/// > Warning: Always capture references with `[weak self]` or `[weak viewModel]`
/// > in the closure to prevent memory leaks.
public struct RouterContextModifier<R: RouteContext>: ViewModifier {

  @Environment(\.router) private var router
  @State private var firstTime: Bool = false
  let object: R.Type
  let perform: (R) -> Void

  public func body(content: Content) -> some View {
    content
      .onAppear {
        router.add(context: object, perform: perform)
      }
  }
}

public extension View {
  /// Registers a context observer for the specified `RouteContext` type.
  ///
  /// Use this modifier to listen for context events triggered by child routes.
  /// The closure is called whenever a matching context is dispatched via
  /// `router.context(_:)` or `router.terminate(_:)`.
  ///
  /// > Warning: If you reference a class instance (e.g. a view model) inside
  /// > the `perform` closure, capture it `[weak]` or `[unowned]` to prevent memory leaks.
  ///
  /// ## Example
  ///
  /// ```swift
  /// .routerContext(UserSelectionContext.self) { [weak viewModel] context in
  ///   viewModel?.selectUser(context.user)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - object: The `RouteContext` type to observe.
  ///   - perform: A closure executed when the context is triggered.
  /// - Returns: A view with the context observer attached.
  func routerContext<R: RouteContext>(_ object: R.Type, perform: @escaping (R) -> Void) -> some View {
    self.modifier(RouterContextModifier(object: object, perform: perform))
  }
}
