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
  @Environment(\.isPresented) private var isPresented
  private let name: String?
  private let destination: Destination
  private var content: Content

  public init(name: String?, destination: Destination, @ViewBuilder content: () ->  Content) {
    self.name = name
    self.destination = destination
    self.content = content()
  }

  public var body: some View {
    WrappedView(name: name, destination: destination, parent: router, isPresented: isPresented, content: content)
  }

  private struct WrappedView: View {

    @State private var router: Router
    private let destination: Destination
    private let content: Content

    init(name: String?, destination: Destination, parent: Router, isPresented: Bool, content: Content) {
      self.destination = destination
      self.router = Router(name: name, parent: parent, isPresented: isPresented)
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
