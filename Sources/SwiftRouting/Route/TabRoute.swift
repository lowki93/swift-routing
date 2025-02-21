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
/// To integrate a tab into a navigation system, instantiate a `RoutingNavigationStack`.
/// This will also create a router associated with the tab:
/// ```swift
/// RoutingNavigationStack(tab: HomeTab.tab1, destination: HomeRoute.self, route: .page1)
/// ```
public typealias TabRoute = Route

extension TabRoute {
  var type: RouterType { .tab(name) }
}
