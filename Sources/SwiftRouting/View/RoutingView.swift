//
//  RoutingView.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/01/2025.
//

import SwiftUI

/// Creates a `NavigationStack` with its own `Router` to manage navigation, sheets, and covers.
///
/// `RoutingView` functions like a standard `NavigationStack`, but it automatically manages
/// the root `Route`, all `RouteDestination` instances, and presentation types such as sheets or covers.
///
/// ## Usage
/// ```swift
/// // For a tab-based navigation with a route as root:
/// RoutingView(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1)
///
/// // For a tab-based navigation with a view as root:
/// RoutingView(tab: HomeTab.tab1, destination: HomeRoute.self) { Page1View() }
///
/// // For a stack-based navigation with a route as root:
/// RoutingView(stack: "Page", destination: HomeRoute.self, root: .page1)
///
/// // For a stack-based navigation with a view as root:
/// RoutingView(stack: "Page", destination: HomeRoute.self) { Page1View() }
/// ```
///
/// ## Closable
/// Any presented `RoutingView` instance is automatically closable.
///
/// ## Notes
/// - This navigation system supports deep linking and maintains navigation state.
/// - It allows navigation operations such as `push`, `present`, and `cover` within the stack.
/// - Works seamlessly with `TabView` by creating independent navigation stacks per tab.
///
/// ## Example with Stack Navigation
/// ```swift
/// RoutingView(stack: "Main", destination: HomeRoute.self, root: .page1)
/// ```
@MainActor
public struct RoutingView<Destination: RouteDestination, Content: View>: View {

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

  /// Initializes a `RoutingView` for tab-based navigation.
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

  /// Initializes a `RoutingView` for tab-based navigation.
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
      .sheet($router.sheet, for: destination)
      .cover($router.cover, for: destination)
      .modifier(CloseModifier())
      .environment(\.router, router)
    }

    @ViewBuilder
    private var root: some View {
      Group {
        if let content {
          content
            .modifier(LifecycleModifier(route: router.root.wrapped))
        } else if let root = router.root.wrapped as? Destination.R {
          Destination[root]
        }
      }
      .id(router.rootID)
    }

    private var navigationStack: some View {
      NavigationStack(path: $router.path) {
        root
          .navigationDestination(destination)
      }
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
