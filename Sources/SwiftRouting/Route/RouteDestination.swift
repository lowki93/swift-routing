//
//  RouteDestination.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import SwiftUI

public protocol RouteDestination: Hashable, Identifiable, Sendable {
  associatedtype Destination: View

  @MainActor @ViewBuilder var view: Destination { get }
}

extension RouteDestination {
  public var id: Int { hashValue }

  @MainActor public func callAsFunction() -> some View {
    view
  }

  @MainActor public func asAnyView() -> AnyView {
      AnyView(view)
  }
}

public struct AnyRouteDestination {
  public var wrapped: any RouteDestination
}

extension AnyRouteDestination: Hashable, Identifiable {
  public var id: Int { wrapped.id }
  public var hashValue: Int { wrapped.hashValue }

  @MainActor public func callAsFunction() -> AnyView {
    wrapped.asAnyView()
  }
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

public extension View {
  func navigationDestination<D: RouteDestination>(_ destination: D.Type) -> some View {
    self.navigationDestination(for: D.self) { $0() }
  }

  func sheet<D: RouteDestination>(_ route: Binding<AnyRouteDestination?>, for destination: D.Type , onDismiss: (() -> Void)? = nil) -> some View {
    self.sheet(item: route, onDismiss: onDismiss) { content in
      RoutedNavigationStack(destination: destination) {
        content()
      }
    }
  }

  func cover<D: RouteDestination>( _ route: Binding<AnyRouteDestination?>, for destination: D.Type , onDismiss: (() -> Void)? = nil) -> some View {
    self.fullScreenCover(item: route, onDismiss: onDismiss) { content in
      RoutedNavigationStack(destination: destination) {
        content()
      }
    }
  }
}
