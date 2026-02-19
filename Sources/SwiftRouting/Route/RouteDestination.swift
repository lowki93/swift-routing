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
/// For environment-driven mapping (`@Environment`, `@EnvironmentObject`,
/// dependency injection), use a dedicated destination wrapper view.
/// See the example on ``view(for:)`` below.
public protocol RouteDestination: Hashable, Identifiable {
  associatedtype R: Route
  associatedtype Destination: View

  /// Returns the correct view associated with a `Route`.
  ///
  /// - Parameter route: The route to display.
  /// - Returns: The corresponding `View`.
  ///
  /// Example with environment values:
  /// ```swift
  /// extension HomeRoute: @retroactive RouteDestination {
  ///   public static func view(for route: HomeRoute) -> some View {
  ///     HomeRouteDestination(route: route)
  ///   }
  /// }
  ///
  /// struct HomeRouteDestination: View {
  ///   @Environment(\.router) private var router
  ///   let route: HomeRoute
  ///
  ///   var body: some View {
  ///     switch route {
  ///       case .page1:
  ///         Page1View()
  ///       case .page2:
  ///         Page2View(onNext: { router.push(.page3("next")) })
  ///       case let .page3(value):
  ///         Page3View(value: value)
  ///     }
  ///   }
  /// }
  /// ```
  @MainActor @ViewBuilder static func view(for route: R) -> Destination
}

extension RouteDestination {
  public var id: Int { hashValue }

  @MainActor public static subscript(route: R) -> some View {
    Self.view(for: route).modifier(LifecycleModifier(route: route))
  }
}
