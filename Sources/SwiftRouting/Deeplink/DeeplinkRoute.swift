//
//  DeeplinkRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 09/02/2025.
//

/// Defines how a deeplink should be handled by the `Router`.
///
/// A `DeeplinkRoute` specifies the navigation path and the optional final route to be displayed.
/// It includes an optional sequence of intermediate routes that construct the navigation path
/// before reaching the target destination.
///
/// ## Examples
/// ```swift
/// // Navigate to a specific route
/// let deeplink = DeeplinkRoute.push(.product(id: 42), path: [.catalog, .category(id: 7)])
///
/// // Just pop to root without navigating
/// let resetDeeplink = DeeplinkRoute<MyRoute>.popToRoot()
/// ```
///
/// `Router.handle(deeplink:)` applies this in order:
/// 1. Close presented children and pop to root
/// 2. Optionally override `root`
/// 3. Push all routes from `path`
/// 4. Navigate to final `route` using `type` (if provided)
///
/// > Note:
/// > Stored properties are internal by design and consumed by the router.
/// > Build deeplinks through the public initializer or factory methods.
public struct DeeplinkRoute<R: Route> {

  /// Optional root route to replace the current root before processing `path` and `route`.
  let root: R?

  /// The presentation type that determines how the final route should be displayed.
  let type: RoutingType

  /// The optional final route to display after processing the deeplink.
  /// When `nil`, the deeplink only performs navigation reset (popToRoot) and optional root/path changes.
  let route: R?

  /// An optional list of intermediate routes to create a navigation path.
  ///
  /// These routes will be pushed sequentially before reaching the final destination.
  let path: [R]

  /// Creates a new deeplink route definition.
  ///
  /// - Parameters:
  ///   - root: Optional root route to replace the current root before navigation.
  ///   - type: The presentation style (e.g., push, sheet, cover, root).
  ///   - route: The final route to be displayed.
  ///   - path: An optional sequence of intermediate routes leading to the final destination.
  public init(root: R? = nil, type: RoutingType, route: R, path: [R] = []) {
    self.type = type
    self.root = root
    self.path = path
    self.route = route
  }
}

// MARK: - Factory Methods

public extension DeeplinkRoute {

  /// Creates a deeplink that only resets navigation to root without navigating to a new route.
  ///
  /// - Parameter root: Optional root route to replace the current root after reset.
  /// - Returns: A deeplink that performs popToRoot and optionally updates the root.
  static func popToRoot(root: R? = nil) -> DeeplinkRoute<R> {
    DeeplinkRoute(root: root, type: .push, route: nil, path: [])
  }

  /// Creates a deeplink that pushes a route onto the navigation stack.
  ///
  /// - Parameters:
  ///   - route: The route to push.
  ///   - root: Optional root route to replace before navigation.
  ///   - path: Optional intermediate routes to push before the final route.
  /// - Returns: A deeplink configured for push navigation.
  static func push(_ route: R, root: R? = nil, path: [R] = []) -> DeeplinkRoute<R> {
    DeeplinkRoute(root: root, type: .push, route: route, path: path)
  }

  /// Creates a deeplink that presents a route as a sheet.
  ///
  /// - Parameters:
  ///   - route: The route to present.
  ///   - withStack: Whether the sheet should contain a navigation stack. Defaults to `true`.
  ///   - root: Optional root route to replace before navigation.
  ///   - path: Optional intermediate routes to push before presenting.
  /// - Returns: A deeplink configured for sheet presentation.
  static func present(_ route: R, withStack: Bool = true, root: R? = nil, path: [R] = []) -> DeeplinkRoute<R> {
    DeeplinkRoute(root: root, type: .sheet(withStack: withStack), route: route, path: path)
  }

  /// Creates a deeplink that presents a route as a full-screen cover.
  ///
  /// - Parameters:
  ///   - route: The route to present as cover.
  ///   - root: Optional root route to replace before navigation.
  ///   - path: Optional intermediate routes to push before presenting.
  /// - Returns: A deeplink configured for cover presentation.
  static func cover(_ route: R, root: R? = nil, path: [R] = []) -> DeeplinkRoute<R> {
    DeeplinkRoute(root: root, type: .cover, route: route, path: path)
  }

  /// Creates a deeplink that updates the root route.
  ///
  /// - Parameter route: The new root route.
  /// - Returns: A deeplink configured to update the root.
  static func updateRoot(_ route: R) -> DeeplinkRoute<R> {
    DeeplinkRoute(root: route, type: .root, route: nil, path: [])
  }

  // MARK: - Internal initializer

  internal init(root: R?, type: RoutingType, route: R?, path: [R]) {
    self.type = type
    self.root = root
    self.path = path
    self.route = route
  }
}

