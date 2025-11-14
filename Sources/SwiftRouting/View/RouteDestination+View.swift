//
//  RouteDestination+View.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

public extension View {
  func navigationDestination<D: RouteDestination>(_ destination: D.Type)  -> some View{
    self.navigationDestination(for: AnyRoute.self) {
      ErrorView(route: $0, destination: destination) { route, _ in
        destination[route].modifier(HideTabBarModifier())
      }
    }
  }

  func sheet<D: RouteDestination>(
    _ route: Binding<AnyRoute?>,
    for destination: D.Type,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    self.sheet(item: route, onDismiss: onDismiss) { route in
      dismissableContent(anyRoute: route, for: destination)
    }
  }

  func cover<D: RouteDestination>(
    _ route: Binding<AnyRoute?>,
    for destination: D.Type,
    onDismiss: (() -> Void)? = nil
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
