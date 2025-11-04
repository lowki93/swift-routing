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
      if let route = $0.wrapped as? D.R {
        destination[$0.wrapped as! D.R]
          .modifier(HideTabBarModifier())
      } else {
        errorView(route: $0, destination: destination)
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
  private func dismissableContent<D: RouteDestination>(
    anyRoute: AnyRoute,
    for destination: D.Type
  ) -> some View {
    // TODO: Add condition to fatalError or not
    if let route = anyRoute.wrapped as? D.R {
      RoutingView(
        type: .presented(route.name),
        inStack: anyRoute.inStack,
        destination: destination,
        root: route
      )
    } else {
      errorView(route: anyRoute, destination: destination)
    }
  }

  private func errorView(route: AnyRoute, destination: (some RouteDestination).Type) -> some View {
    Text("Route '\(route.description)' are not define in '\(String(describing: destination.self))'")
      .padding()
  }
}
