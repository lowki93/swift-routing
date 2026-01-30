//
//  RouteDestination+View.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

/// View extensions for integrating route destinations with SwiftUI navigation.
///
/// These extensions connect `RouteDestination` types with SwiftUI's navigation system,
/// enabling type-safe navigation using your route enums.
public extension View {

  /// Configures the view to display destinations for pushed routes.
  ///
  /// This modifier sets up the `NavigationStack` to handle routes pushed via
  /// `router.push(_:)`. It maps each `AnyRoute` to its corresponding view
  /// using the provided `RouteDestination` type.
  ///
  /// You typically don't call this directly; `RoutingView` applies it automatically.
  ///
  /// - Parameter destination: The `RouteDestination` type that maps routes to views.
  /// - Returns: A view configured to display navigation destinations.
  func navigationDestination<D: RouteDestination>(_ destination: D.Type)  -> some View{
    self.navigationDestination(for: AnyRoute.self) {
      ErrorView(route: $0, destination: destination) { route, _ in
        destination[route].modifier(HideTabBarModifier())
      }
    }
  }

  /// Presents a route as a modal sheet.
  ///
  /// This modifier displays the bound route as a sheet presentation. When the route
  /// is non-nil, the sheet appears; when nil, it dismisses.
  ///
  /// The presented route gets its own `RoutingView` with a `.presented` router type,
  /// allowing full navigation capabilities within the sheet.
  ///
  /// You typically don't call this directly; `RoutingView` applies it automatically
  /// to handle `router.present(_:)` calls.
  ///
  /// - Parameters:
  ///   - route: A binding to the route to present, or `nil` to dismiss.
  ///   - destination: The `RouteDestination` type that maps routes to views.
  ///   - onDismiss: A closure called when the sheet is dismissed.
  /// - Returns: A view that can present sheets for routes.
  func sheet<D: RouteDestination>(
    _ route: Binding<AnyRoute?>,
    for destination: D.Type,
    onDismiss: @escaping () -> Void
  ) -> some View {
    self.sheet(item: route, onDismiss: onDismiss) { route in
      dismissableContent(anyRoute: route, for: destination)
    }
  }

  /// Presents a route as a full-screen cover.
  ///
  /// This modifier displays the bound route as a full-screen cover presentation.
  /// When the route is non-nil, the cover appears; when nil, it dismisses.
  ///
  /// The presented route gets its own `RoutingView` with a `.presented` router type,
  /// allowing full navigation capabilities within the cover.
  ///
  /// You typically don't call this directly; `RoutingView` applies it automatically
  /// to handle `router.cover(_:)` calls.
  ///
  /// - Parameters:
  ///   - route: A binding to the route to present, or `nil` to dismiss.
  ///   - destination: The `RouteDestination` type that maps routes to views.
  ///   - onDismiss: A closure called when the cover is dismissed.
  /// - Returns: A view that can present full-screen covers for routes.
  func cover<D: RouteDestination>(
    _ route: Binding<AnyRoute?>,
    for destination: D.Type,
    onDismiss: @escaping () -> Void
  ) -> some View {
    self.fullScreenCover(item: route, onDismiss: onDismiss) { route in
      dismissableContent(anyRoute: route, for: destination)
    }
  }

  @ViewBuilder
  private func dismissableContent<D: RouteDestination>(anyRoute: AnyRoute, for destination: D.Type) -> some View {
    ErrorView(route: anyRoute, destination: destination) { route, destination in
      RoutingView(
        type: .presented(route.name),
        inStack: anyRoute.inStack,
        destination: destination,
        root: route
      )
    }
  }
}
