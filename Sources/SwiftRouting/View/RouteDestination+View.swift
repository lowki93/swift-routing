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
    }
  }

  func sheet<D: RouteDestination>(
    _ route: Binding<AnyRoute?>,
    for destination: D.Type,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    self.sheet(item: route, onDismiss: onDismiss) { route in
      dismissableContent(route: route, for: destination)
    }
  }

  func cover<D: RouteDestination>(
    _ route: Binding<AnyRoute?>,
    for destination: D.Type,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    self.fullScreenCover(item: route, onDismiss: onDismiss) { route in
      dismissableContent(route: route, for: destination)
    }
  }

  private func dismissableContent<D: RouteDestination>(
    route: AnyRoute,
    for destination: D.Type
  ) -> some View {
    RoutedNavigationStack(type: .presented(route.name), destination: destination) {
      // TODO: Add condition to fatalError or not
      if let route = route.wrapped as? D.R {
        destination[route]
          .modifier(DismissModifier())
      } else {
        Text("Route '\(route)' are not define in '\(D.self)'")
          .padding()
      }
    }
  }
}
