//
//  RouteDestination.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import SwiftUI

public protocol RouteDestination: Hashable, Identifiable {
  associatedtype R: Route
  associatedtype Destination: View

  @MainActor @ViewBuilder static func view(for route: R) -> Destination
}

public extension RouteDestination {
  var id: Int { hashValue }

  @MainActor static subscript(route: R) -> some View {
    Self.view(for: route).modifier(LifecycleModifier(route: route))
  }
}
