//
//  RoutedNavigationStack.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/01/2025.
//

import SwiftUI

@MainActor
public struct RoutedNavigationStack<Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var parent
  private let type: RouterType
  private let destination: Destination.Type
  private let content: Content

  public init(type: RouterType, destination: Destination.Type, @ViewBuilder content: () ->  Content) {
    self.type = type
    self.destination = destination
    self.content = content()
  }

  public var body: some View {
    WrappedView(router: Router(type: type, parent: parent), destination: destination, content: content)
  }

  private struct WrappedView: View {

    @StateObject var router: Router
    let destination: Destination.Type
    let content: Content

    public var body: some View {
      NavigationStack(path: $router.path) {
        content
          .navigationDestination(destination)
      }
      .sheet($router.sheet, for: destination)
      .cover($router.cover, for: destination)
      .environment(\.router, router)
    }
  }
}
