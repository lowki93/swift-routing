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
public struct DeeplinkRoute<R: Route> {

  /// The presentation type that determines how the final route should be displayed.
  let type: RoutingType

  /// An optional list of intermediate routes to create a navigation path.
  ///
  /// These routes will be pushed sequentially before reaching the final destination.
  let path: [R]

  /// The final route to display after processing the deeplink.
  let route: R

  /// Creates a new deeplink route definition.
  ///
  /// - Parameters:
  ///   - type: The presentation style (e.g., push, sheet, cover, root).
  ///   - path: An optional sequence of intermediate routes leading to the final destination.
  ///   - route: The final route to be displayed.
  public init(type: RoutingType, path: [R] = [], route: R) {
    self.type = type
    self.path = path
    self.route = route
  }
}
