//
//  RoutingNavigationStack.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/01/2025.
//

import SwiftUI

// Creates a `NavigationStack` with its own `Router` to manage navigation, sheets, and covers.
///
/// `RoutingNavigationStack` functions like a standard `NavigationStack`, but it automatically manages
/// the root `Route`, all `RouteDestination` instances, and presentation types such as sheets or covers.
///
/// ## Usage
/// ```swift
/// // For a tab-based navigation:
/// RoutingNavigationStack(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1)
///
/// // For a stack-based navigation:
/// RoutingNavigationStack(stack: "Page", destination: HomeRoute.self, root: .page1)
/// ```
///
/// ## Closable
/// Any presented `RoutingNavigationStack` instance is automatically closable.
@MainActor
public struct RoutingNavigationStack<Destination: RouteDestination>: View {

  @Environment(\.router) private var parent
  private let type: RouterType
  private let destination: Destination.Type
  private let root: Destination.R

  init(type: RouterType, destination: Destination.Type, root: Destination.R) {
    self.type = type
    self.destination = destination
    self.root = root
  }

  /// Initializes a `RoutingNavigationStack` for tab-based navigation.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with the navigation.
  ///   - destination: The destination type conforming to `RouteDestination`.
  ///   - root: The initial route.
  public init(tab: any TabRoute, destination: Destination.Type, root: Destination.R) {
    self.init(type: tab.type, destination: destination, root: root)
  }

  /// Initializes a `RoutingNavigationStack` for stack-based navigation.
  ///
  /// - Parameters:
  ///   - name: The name of the navigation stack.
  ///   - destination: The destination type conforming to `RouteDestination`.
  ///   - root: The initial route.
  public init(stack name: String, destination: Destination.Type, root: Destination.R) {
    self.init(type: .stack(name), destination: destination, root: root)
  }

  public var body: some View {
    WrappedView(
      router: Router(root: AnyRoute(wrapped: root), type: type, parent: parent),
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
