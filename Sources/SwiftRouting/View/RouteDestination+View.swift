//
//  RouteDestination+View.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

public extension View {
  func navigationDestination<D: RouteDestination>(_ destination: D.Type)  -> some View{
    self.navigationDestination(for: D.R.self) {
      destination[$0]
        .modifier(HideTabBarModifier())
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
        present: route.name,
        inStack: anyRoute.inStack,
        destination: destination,
        root: route
      )
    } else {
      Text("Route '\(anyRoute)' are not define in '\(D.self)'")
        .padding()
    }
  }
}
