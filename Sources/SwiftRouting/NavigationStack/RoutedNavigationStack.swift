//
//  RoutedNavigationStack.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/01/2025.
//

import SwiftUI

@MainActor
public struct RoutedNavigationStack<Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var router
  private let name: String?
  private let destination: Destination.Type
  private var content: Content

  public init(name: String?, destination: Destination.Type, @ViewBuilder content: () -> Content) {
    self.name = name
    self.destination = destination
    self.content = content()
  }

  public var body: some View {
    WrappedView(name: name, destination: destination, parent: router, content: content)
  }

  private struct WrappedView: View {

    @State private var router: Router
    private let destination: Destination.Type

    private let content: Content

    init(name: String?, destination: Destination.Type, parent: Router, content: Content) {
      self.destination = destination
      self.router = Router(name: name, parent: parent)
      self.content = content
    }

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
