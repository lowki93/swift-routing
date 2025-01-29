//
//  RouteDestination.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import SwiftUI

public protocol RouteDestination: Route {
  associatedtype Destination: View

  @MainActor @ViewBuilder var view: Destination { get }
}

extension RouteDestination {
  var id: Int { hashValue }
  var name: String { name }

  @MainActor public func callAsFunction() -> some View {
    view.modifier(LifecycleModifier(route: self))
  }
}

public struct AnyRouteDestination: Identifiable {
  public var wrapped: any RouteDestination
  public var id: Int { wrapped.id }

  @MainActor public func callAsFunction() -> AnyView {
    AnyView(wrapped())
  }
}

// RouteDestination2

public protocol RouteDestination2: Hashable, Identifiable {
  associatedtype R: Route
  associatedtype Destination: View

  @MainActor @ViewBuilder func view(for route: R) -> Destination
}

extension RouteDestination2 {
  var id: Int { hashValue }

  @MainActor public func callAsFunction(_ route: R) -> some View {
    view(for: route).modifier(LifecycleModifier(route: route))
  }
}

struct AnyRouteDestination2<R: Route, D: RouteDestination2>: Identifiable {
  public var id: Int { wrapped.id }
  public var wrapped: D

  @MainActor public func callAsFunction(_ route: any Route) -> AnyView where D.R == R {
    AnyView(wrapped(route as! R))
  }
}
