//
//  RouterDidDismissModifier.swift
//  swift-routing
//

import SwiftUI

/// A view modifier that observes the end of a sheet or cover dismissal.
///
/// `RouterDidDismissModifier` is notified when SwiftUI reports that a modal presented by a
/// router has finished dismissing, after the dismiss animation. Use it when something must be
/// presented only once the previous modal is fully gone.
struct RouterDidDismissModifier: ViewModifier {

  @Environment(\.router) private var router: Router
  let perform: (Router) -> Void

  func body(content: Content) -> some View {
    content.onReceive(router.dismissed, perform: perform)
  }
}

public extension View {
  /// Observes the end of a sheet or cover dismissal in the current router hierarchy.
  ///
  /// Unlike ``routerPresent(perform:)``, which reports the state change as soon as it happens,
  /// the closure is called once per dismissal, after the dismiss animation has finished.
  ///
  /// ## Example
  ///
  /// ```swift
  /// .routerDidDismiss { router in
  ///   if let pending = pendingModal {
  ///     router.present(pending)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameter perform: A closure called with the `Router` whose modal was dismissed.
  /// - Returns: A view that observes modal dismissals.
  func routerDidDismiss(perform: @escaping (Router) -> Void) -> some View {
    self.modifier(RouterDidDismissModifier(perform: perform))
  }
}
