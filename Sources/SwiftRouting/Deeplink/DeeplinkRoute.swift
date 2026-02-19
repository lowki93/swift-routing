//
//  DeeplinkRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 09/02/2025.
//

/// Defines how a deeplink should be handled by the `Router`.
///
/// A `DeeplinkRoute` specifies the navigation path and the final route to be displayed.
/// It includes an optional sequence of intermediate routes that construct the navigation path
/// before reaching the target destination.
///
/// ## Example
/// ```swift
/// let deeplink = DeeplinkRoute(
///   root: .home,
///   type: .push,
///   route: .product(id: 42),
///   path: [.catalog, .category(id: 7)]
/// )
/// ```
///
/// `Router.handle(deeplink:)` applies this in order:
/// 1. Optionally override `root`
/// 2. Push all routes from `path`
/// 3. Navigate to final `route` using `type`
///
/// > Note:
/// > Stored properties are internal by design and consumed by the router.
/// > Build deeplinks through the public initializer.
public struct DeeplinkRoute<R: Route> {

  /// Optional root route to replace the current root before processing `path` and `route`.
  let root: R?

  /// The presentation type that determines how the final route should be displayed.
  let type: RoutingType

  /// The final route to display after processing the deeplink.
  let route: R
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

