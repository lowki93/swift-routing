//
//  RoutedNavigationStack.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/01/2025.
//

import SwiftUI

@MainActor
public struct RoutedNavigationStack<Destination: RouteDestination>: View {

  @Environment(\.router) private var parent
  private let type: RouterType
  private let destination: Destination.Type
  private let route: Destination.R

  public init(type: RouterType, destination: Destination.Type, route: Destination.R) {
    self.type = type
    self.destination = destination
    self.route = route
  }

  public var body: some View {
    WrappedView(router: Router(type: type, parent: parent), destination: destination, route: route)
  }

  private struct WrappedView: View {

    @StateObject var router: Router
    let destination: Destination.Type
    let route: Destination.R

    public var body: some View {
      NavigationStack(path: $router.path) {
        rootView
          .navigationDestination(destination)
      }
      .sheet($router.sheet, for: destination)
      .cover($router.cover, for: destination)
      .modifier(CloseModifier())
      .environment(\.router, router)
    }

    @ViewBuilder
    private var rootView: some View {
      if let route = router.rootRoute?.wrapped as? Destination.R {
        destination[route]
      } else {
        destination[route]
      }
    }
  }
}
