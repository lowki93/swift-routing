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
  var hideTabBarOnPush: Bool { get }
}

extension TabRoute {
  var type: RouterType { .tab(name, hideTabBarOnPush: hideTabBarOnPush) }

  /// Whether the tab bar should be hidden when pushing views onto this tab's navigation stack.
  ///
  /// Override this property in your `TabRoute` implementation to hide the tab bar
  /// when navigating deeper into a tab's stack. Default is `false`.
  ///
  /// ```swift
  /// enum HomeTab: TabRoute {
  ///   case home, settings
  ///
  ///   var hideTabBarOnPush: Bool {
  ///     self == .settings // Hide tab bar only in settings tab
  ///   }
  /// }
  /// ```
  public var hideTabBarOnPush: Bool { false }
}

/// A type-erased wrapper for any `TabRoute` type.
///
/// `AnyTabRoute` enables storing and manipulating tab routes of different concrete types
/// in a uniform way. It is used internally by `TabRouter` to track the currently selected tab.
///
/// ## Overview
///
/// Similar to `AnyRoute`, this wrapper provides type erasure for tab routes while
/// preserving identity through the hash value. You typically don't create `AnyTabRoute`
/// instances directly; the `TabRouter` manages them automatically.
///
/// ```swift
/// // Access the current tab from TabRouter
/// let currentTab = tabRouter.tab.wrapped as? HomeTab
/// ```
public struct AnyTabRoute: Identifiable, Equatable {
  /// A unique identifier derived from the wrapped tab route's hash value.
  public var id: Int { wrapped.hashValue }

  /// The underlying tab route instance.
  ///
  /// Access this property when you need to work with the concrete tab type,
  /// typically by casting: `if let tab = anyTabRoute.wrapped as? HomeTab { ... }`
  var wrapped: any TabRoute

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}
