//
//  TabRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

import Foundation

/// Defines the available tabs for a `TabView`.
///
/// The `TabRoute` protocol represents an enumeration of all available tabs.
///
/// ## Defining a Tab
/// To define a tab, create an enumeration conforming to `TabRoute`.
/// ```swift
/// public enum HomeTab: TabRoute {
///   case tab1
///   case tab2
///   case tab3
///
///   public var name: String {
///     switch self {
///     case .tab1: "Tab 1"
///     case .tab2: "Tab 2"
///     case .tab3: "Tab 3"
///     }
///   }
/// }
/// ```
///
/// ## Associating a Tab with a Navigation Stack
/// To integrate a tab into a navigation system, instantiate a `RoutingView`.
/// This will also create a router associated with the tab:
/// ```swift
/// RoutingView(tab: HomeTab.tab1, destination: HomeRoute.self, route: .page1)
/// ```
public protocol TabRoute: Route {
  var hideTabBarOnPush: Bool { get}
}

extension TabRoute {
  var type: RouterType { .tab(name, hideTabBarOnPush: hideTabBarOnPush) }

  public var hideTabBarOnPush: Bool { false }
}

public struct AnyTabRoute: Identifiable, Equatable {
  public var id: Int { wrapped.hashValue }
  var wrapped: any TabRoute

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}
