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
  private let destination: Destination.Type
  private var content: Content

  public init(name: String?, destination: Destination.Type, @ViewBuilder content: () ->  Content) {
    self.name = name
    self.destination = destination
    self.content = content()
  }

  public var body: some View {
    WrappedView(
      router: Router(name: name, parent: router, isPresented: isPresented),
      destination: destination,
      content: content
    )
  }

  private struct WrappedView: View {

    @State var router: Router
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
