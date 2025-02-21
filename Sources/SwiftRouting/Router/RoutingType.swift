//
//  RoutingType.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import Foundation

/// Defines how a `Route` should be presented within the navigation system.
///
/// Each case corresponds to a method for presenting the route correctly:
/// ```swift
/// // Push navigation
/// router.push(HomeRoute.page1)
///
/// // Present as a sheet
/// router.present(HomeRoute.page1)
///
/// // Present as a full-screen cover
/// router.cover(HomeRoute.page1)
/// ```
///
/// > **Warning:** `RoutingType.root` is only available for deep linking, allowing you to override the current root of the `NavigationStack`.
public enum RoutingType: CustomStringConvertible {
  /// Sets the root of a navigation stack.
  case root
  /// Pushes a route onto the navigation stack.
  case push
  /// Presents a route as a sheet.
  case sheet
  /// Presents a route as a full-screen cover.
  case cover

  public var description: String {
    switch self {
    case .root: "root"
    case .push: "push"
    case .sheet: "sheet"
    case .cover: "cover"
    }
  }
}
