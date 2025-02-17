//
//  RouteDestination.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import SwiftUI

/// Protocol that associates a `Route` with its corresponding `View`.
///
/// `RouteDestination` is a protocol that defines a static method to return the view
/// corresponding to a given route.
///
/// ## Implementing `RouteDestination`
/// You can directly conform your route to this protocol:
/// ```swift
/// extension HomeRoute: @retroactive RouteDestination {
///   public static func view(for route: HomeRoute) -> some View {
///     switch route {
///       case .page1: Page1View()
///       case let .page2(value): Page2View(value: value)
///       case let .page3(value): Page3View(value: value)
///     }
///   }
/// }
/// ```
///
/// Alternatively, you can create a separate view if you need to use an environment object:
/// ```swift
/// extension HomeRoute: @retroactive RouteDestination {
///   public static func view(for route: HomeRoute) -> some View {
///     HomeRouteDestination(route: route)
///   }
/// }
/// ```
public protocol RouteDestination: Hashable, Identifiable {
  associatedtype R: Route
  associatedtype Destination: View

  /// Return the corect view link to a Route
  /// ```swift
  /// extension HomeRoute: @retroactive RouteDestination {
  ///   public static func view(for route: HomeRoute) -> some View {
  ///     switch route {
  ///       case .page1: Page1View()
  ///       case let .page2(value): Page2View(value: value)
  ///       case let .page3(value): Page3View(value: value)
  ///     }
  ///   }
  /// }
  /// ```
  @MainActor @ViewBuilder static func view(for route: R) -> Destination
}

extension RouteDestination {
  public var id: Int { hashValue }

  @MainActor static subscript(route: R) -> some View {
    Self.view(for: route).modifier(LifecycleModifier(route: route))
  }
}
