//
//  RouteDestination+View.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

public extension View {
  func navigationDestination<D: RouteDestination>(_ destination: D.Type) -> some View {
    self.navigationDestination(for: D.self) { content in
      content()
    }
  }

  func sheet<D: RouteDestination>(
    _ route: Binding<AnyRouteDestination?>,
    for destination: D.Type,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    self.sheet(item: route, onDismiss: onDismiss) { content in
      RoutedNavigationStack(name: "Sheet", destination: destination) {
        content()
          .modifier(DismissModifier())
      }
    }
  }

  func cover<D: RouteDestination>(
    _ route: Binding<AnyRouteDestination?>,
    for destination: D.Type
    , onDismiss: (() -> Void)? = nil
  ) -> some View {
    self.fullScreenCover(item: route, onDismiss: onDismiss) { content in
      RoutedNavigationStack(name: "Cover", destination: destination) {
        content()
          .modifier(DismissModifier())
      }
    }
  }
}
