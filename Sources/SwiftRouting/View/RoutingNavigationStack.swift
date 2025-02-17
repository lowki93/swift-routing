//
//  RoutingNavigationStack.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/01/2025.
//

import SwiftUI

@MainActor
public struct RoutingNavigationStack<Destination: RouteDestination>: View {

  @Environment(\.router) private var parent
  private let type: RouterType
  private let destination: Destination.Type
  private let route: Destination.R

  public init(type: RouterType, destination: Destination.Type, route: Destination.R) {
    self.type = type
    self.destination = destination
    self.route = route
  }

  public init(tab: any TabRoute, destination: Destination.Type, route: Destination.R) {
    self.init(type: tab.type, destination: destination, route: route)
  }

  public var body: some View {
    WrappedView(
      router: Router(root: AnyRoute(wrapped: route), type: type, parent: parent),
      destination: destination
    )
  }

  private struct WrappedView: View {

    @StateObject var router: Router
    let destination: Destination.Type

    public var body: some View {
      if let root = router.root?.wrapped as? Destination.R {
        NavigationStack(path: $router.path) {
          destination[root]
            .id(router.rootID)
            .navigationDestination(destination)
        }
        .sheet($router.sheet, for: destination)
        .cover($router.cover, for: destination)
        .modifier(CloseModifier())
        .environment(\.router, router)
      }
    }
  }
}
