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
/// // For a tab-based navigation with a route as root:
/// RoutingNavigationStack(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1)
///
/// // For a tab-based navigation with a view as root:
/// RoutingNavigationStack(tab: HomeTab.tab1, destination: HomeRoute.self) { Page1View() }
///
/// // For a stack-based navigation with a route as root:
/// RoutingNavigationStack(stack: "Page", destination: HomeRoute.self, root: .page1)
///
/// // For a stack-based navigation with a view as root:
/// RoutingNavigationStack(stack: "Page", destination: HomeRoute.self) { Page1View() }
/// ```
///
/// ## Closable
/// Any presented `RoutingNavigationStack` instance is automatically closable.
///
/// ## Notes
/// - This navigation system supports deep linking and maintains navigation state.
/// - It allows navigation operations such as `push`, `present`, and `cover` within the stack.
/// - Works seamlessly with `TabView` by creating independent navigation stacks per tab.
///
/// ## Example with `TabView`
/// ```swift
/// TabView {
///     RoutingNavigationStack(tab: HomeTab.tab1, destination: HomeRoute.self, root: .page1)
///     RoutingNavigationStack(tab: HomeTab.tab2, destination: HomeRoute.self) { Page2View() }
/// }
/// ```
///
/// ## Example with Stack Navigation
/// ```swift
/// RoutingNavigationStack(stack: "Main", destination: HomeRoute.self, root: .page1)
/// ```
@MainActor
public struct RoutingNavigationStack<Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var parent
  private let type: RouterType
  // TODO: [TabBarRouter] mode in RoutingTabBar
  private let hideTabBar: Bool
  private let destination: Destination.Type
  private let root: Destination.R?
  private let content: Content?

  init(type: RouterType, hideTabBar: Bool = false, destination: Destination.Type, root: Destination.R?, content: (() -> Content)?) {
    self.type = type
    self.hideTabBar = hideTabBar
    self.destination = destination
    self.root = root
    self.content = content?()
  }

  /// Initializes a `RoutingNavigationStack` for tab-based navigation.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with the navigation, conforming to `TabRoute`.
  ///   - destination: The type conforming to `RouteDestination`, defining the available routes.
  ///   - content: A `ViewBuilder` closure providing the root view for this tab's navigation stack.
  public init(tab: any TabRoute, hideTabBar: Bool, destination: Destination.Type, @ViewBuilder content: @escaping () -> Content) {
    self.init(type: tab.type, hideTabBar: hideTabBar, destination: destination, root: nil, content: content)
  }

  /// Initializes a `RoutingNavigationStack` for tab-based navigation.
  ///
  /// - Parameters:
  ///   - tab: The name of the navigation stack.
  ///   - destination: The type conforming to `RouteDestination`, defining the available routes.
  ///   - content: A `ViewBuilder` closure providing the root view for this tab's navigation stack.
  public init(stack name: String, destination: Destination.Type, @ViewBuilder content: @escaping () -> Content) {
    self.init(type: .stack(name), destination: destination, root: nil, content: content)
  }

  public var body: some View {
    WrappedView(
      router: Router(root: root.flatMap(AnyRoute.init(wrapped:)), type: type, parent: parent, hideTabBar: hideTabBar),
      destination: destination,
      content: content
    )
  }

  private struct WrappedView: View {

    @StateObject var router: Router
    let destination: Destination.Type
    let content: Content?

    public var body: some View {
      NavigationStack(path: $router.path) {
        root
          .id(router.rootID)
          .navigationDestination(destination)
      }
      .sheet($router.sheet, for: destination)
      .cover($router.cover, for: destination)
      .modifier(CloseModifier())
      .environment(\.router, router)
    }

    @ViewBuilder
    private var root: some View {
      if let root = router.root?.wrapped as? Destination.R {
        Destination[root]
      } else if let content {
        content
      }
    }
  }
}

extension RoutingNavigationStack where Content == EmptyView {
  init(type: RouterType, hideTabBar: Bool = false ,destination: Destination.Type, root: Destination.R) {
    self.init(type: type, hideTabBar: hideTabBar, destination: destination, root: root, content: nil)
  }

  /// Initializes a `RoutingNavigationStack` for tab-based navigation.
  ///
  /// - Parameters:
  ///   - tab: The tab associated with the navigation.
  ///   - destination: The destination type conforming to `RouteDestination`.
  ///   - root: The initial route.
  public init(tab: any TabRoute, hideTabBar: Bool, destination: Destination.Type, root: Destination.R) {
    self.init(type: tab.type, hideTabBar: hideTabBar, destination: destination, root: root)
  }

  /// Initializes a `RoutingNavigationStack` for stack-based navigation.
  ///
  /// - Parameters:
  ///   - name: The name of the navigation stack.
  ///   - destination: The destination type conforming to `RouteDestination`.
  ///   - root: The initial route.
  public init(stack name: String, destination: Destination.Type, root: Destination.R) {
    self.init(type: .stack(name), destination: destination, root: root, content: nil)
  }
}
