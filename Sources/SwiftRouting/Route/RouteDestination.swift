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

extension RouteDestination {
  public var id: Int { hashValue }

  @MainActor public static subscript(route: R) -> some View {
    Self.view(for: route).modifier(LifecycleModifier(route: route))
  }
}
