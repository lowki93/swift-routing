//
//  RouteDestination.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import SwiftUI

public protocol RouteDestination: Hashable, Identifiable {
  associatedtype Content: View

  @MainActor @ViewBuilder var view: Content { get }
}

extension RouteDestination {
  public var id: Int { hashValue }
}

public extension View {
  func navigationDestination<D: RouteDestination>(_ destination: D.Type) -> some View {
    self.navigationDestination(for: D.self) { destination in
      destination()
    }
  }
}
