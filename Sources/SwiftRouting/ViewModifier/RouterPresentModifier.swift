//
//  RouterPresentModifier.swift
//  swift-routing
//
//  Created by Kévin Budain on 11/6/25.
//

import SwiftUI

/// A view modifier that observes presentation state changes in the router.
///
/// `RouterPresentModifier` listens for sheet and cover presentation events,
/// notifying you when a modal is presented or dismissed.
///
/// ## Overview
///
/// Use this modifier (via the `routerPresent(perform:)` view extension) to react
/// to presentation changes, such as updating UI state or tracking analytics.
///
/// ```swift
/// struct ContentView: View {
///   @State private var isModalPresented = false
///
///   var body: some View {
///     MainContent()
///       .routerPresent { isPresented, router in
///         isModalPresented = isPresented
///         print("Modal \(isPresented ? "presented" : "dismissed") from \(router)")
///       }
///   }
/// }
/// ```
public struct RouterPresentModifier: ViewModifier {

  @Environment(\.router) private var router: Router
  let perform: (Bool, BaseRouter) -> Void

  public func body(content: Content) -> some View {
    content.onReceive(router.present, perform: perform)
  }
}

public extension View {
  /// Observes presentation state changes (sheet/cover) in the current router.
  ///
  /// The closure is called whenever a modal (sheet or cover) is presented or dismissed
  /// from the current router.
  ///
  /// ## Example
  ///
  /// ```swift
  /// .routerPresent { isPresented, router in
  ///   if isPresented {
  ///     analytics.track("modal_opened")
  ///   } else {
  ///     analytics.track("modal_closed")
  ///   }
  /// }
  /// ```
  ///
  /// - Parameter perform: A closure called when presentation state changes.
  ///   - `isPresented`: `true` when a modal is presented, `false` when dismissed.
  ///   - `router`: The router that triggered the presentation change.
  /// - Returns: A view that observes presentation changes.
  func routerPresent(perform: @escaping (Bool, BaseRouter) -> Void) -> some View {
    self.modifier(RouterPresentModifier(perform: perform))
  }
}
