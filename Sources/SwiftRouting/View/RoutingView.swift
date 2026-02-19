//
//  RoutingView.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/01/2025.
//

import SwiftUI

/// Creates a navigation container with its own `Router`.
///
/// `RoutingView` is the entry point for SwiftRouting. It owns a router scope, maps routes
/// through `RouteDestination`, and handles stack, sheet, and cover presentations.
///
/// Use it as:
/// - a standard stack container (`RoutingView(destination:root:)`)
/// - a tab-scoped stack (`RoutingView(tab:destination:root:)`)
/// - a custom root-content container (initializers with `@ViewBuilder content`)
///
/// ## Examples
/// ```swift
/// // Standard stack with a route root
/// RoutingView(destination: HomeRoute.self, root: .page1)
///
/// // Standard stack with a custom root view
/// RoutingView(destination: HomeRoute.self, root: .page1) { Page1View() }
///
/// // Tab-scoped stack with a route root
/// RoutingView(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1)
///
/// // Tab-scoped stack with a custom root view
/// RoutingView(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1) { Page1View() }
/// ```
///
/// ## Notes
/// - Presented routing scopes are dismissible via `router.close()`.
/// - Each tab can own an independent router stack.
/// - Supports deep links and full programmatic navigation (`push`, `present`, `cover`, `update(root:)`).
@MainActor
public struct  RoutingView<Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var router
  @Environment(\.tabRouter) private var tabRouter
  private let type: RouterType
  private let inStack: Bool
  private let destination: Destination.Type
  private let root: Destination.R
  private let content: Content?
  private var parent: BaseRouter {
    if case .tab = type {
      return tabRouter ?? router
    }
    return router
  }

  init(
    type: RouterType,
    inStack: Bool,
    destination: Destination.Type,
    root: Destination.R,
    content: (() -> Content)?
  ) {
    self.type = type
    self.inStack = inStack
    self.destination = destination
    self.root = root
    self.content = content?()
  }

  /// Initializes a `RoutingView` for tab-based navigation with custom root content.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with the navigation, conforming to `TabRoute`.
  ///   - destination: The type conforming to `RouteDestination`, defining the available routes.
  ///   - root: The initial route.
  ///   - content: A `ViewBuilder` closure providing the root view for this tab's navigation stack.
  public init(
    tab: some TabRoute,
    destination: Destination.Type,
    root: Destination.R,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.init(type: tab.type, inStack: true, destination: destination, root: root, content: content)
  }

  /// Initializes a `RoutingView` for stack-based navigation with custom root content.
  ///
  /// - Parameters:
  ///   - destination: The type conforming to `RouteDestination`, defining the available routes.
  ///   - root: The initial route.
  ///   - content: A `ViewBuilder` closure providing the root view for this tab's navigation stack.
  public init(
    destination: Destination.Type,
    root: Destination.R,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.init(type: .stack(root.name), inStack: true, destination: destination, root: root, content: content)
  }

  public var body: some View {
    WrappedView(
      router: Router(root: AnyRoute(wrapped: root, inStack: inStack), type: type, parent: parent),
      inStack: inStack,
      destination: destination,
      content: content
    )
  }

  private struct WrappedView: View {

    @StateObject var router: Router
    let inStack: Bool
    let destination: Destination.Type
    let content: Content?

    public var body: some View {
      Group {
        if inStack {
          navigationStack
        } else {
          root
        }
      }
      .sheet($router.sheet, for: destination, onDismiss: dismiss)
      .cover($router.cover, for: destination, onDismiss: dismiss)
      .modifier(CloseModifier())
      .environment(\.router, router)
    }

    @ViewBuilder
    private var root: some View {
      Group {
        if let content {
          content.modifier(LifecycleModifier(route: router.root.wrapped))
        } else if let root = router.root.wrapped as? Destination.R {
          Destination[root]
        }
      }
      .id(router.root.id)
    }

    private var navigationStack: some View {
      NavigationStack(path: $router.path) {
        root
          .navigationDestination(destination)
      }
    }

    private func dismiss() {
      router.log(.onAppear(router.currentRoute.wrapped))
    }
  }
}

extension RoutingView where Content == EmptyView {

  init(type: RouterType, inStack: Bool, destination: Destination.Type, root: Destination.R) {
    self.init(type: type, inStack: inStack, destination: destination, root: root, content: nil)
  }

  /// Initializes a `RoutingView` for tab-based navigation.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with the navigation.
  ///   - destination: The destination type conforming to `RouteDestination`.
  ///   - root: The initial route.
  public init(tab: some TabRoute, destination: Destination.Type, root: Destination.R) {
    self.init(type: tab.type, inStack: true, destination: destination, root: root, content: nil)
  }

  /// Initializes a `RoutingView` for stack-based navigation.
  ///
  /// - Parameters:
  ///   - destination: The destination type conforming to `RouteDestination`.
  ///   - root: The initial route.
  public init(destination: Destination.Type, root: Destination.R) {
    self.init(type: .stack(root.name), inStack: true, destination: destination, root: root, content: nil)
  }
}
