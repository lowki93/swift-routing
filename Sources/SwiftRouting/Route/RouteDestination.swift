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

  @MainActor @ViewBuilder func view(for route: R) -> Destination
}

public extension RouteDestination {
  var id: Int { hashValue }

  @MainActor func callAsFunction(_ route: R) -> some View {
    view(for: route).modifier(LifecycleModifier(route: route))
  }
}

struct AnyRouteDestination2<R: Route, D: RouteDestination>: Identifiable {
  public var id: Int { wrapped.id }
  public var wrapped: D

  @MainActor public func callAsFunction(_ route: any Route) -> AnyView where D.R == R {
    AnyView(wrapped(route as! R))
  }
}
