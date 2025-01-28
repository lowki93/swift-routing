//
//  RouteDestination.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import SwiftUI

public protocol RouteDestination: Route, Identifiable {
  associatedtype Destination: View

  @MainActor @ViewBuilder var view: Destination { get }
}

public extension RouteDestination {
  var id: Int { hashValue }
  var name: String { name }

  @MainActor func callAsFunction() -> some View {
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
