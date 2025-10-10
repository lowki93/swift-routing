//
//  LoggerAction.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import Foundation

/// Represents the type of action logged by the router.
///
/// `LoggerAction` defines various categories of events that can be tracked within the navigation system.
/// It provides insight into lifecycle events, navigation changes, and user interactions.
///
/// ## Cases
/// - `routerLifecycle`: Logs the initialization and deallocation of a router.
/// - `navigation`: Logs when a route is displayed.
/// - `action`: Logs actions related to navigation, dismissals, and back actions.
/// - `viewLifecycle`: Logs `onAppear` and `onDisappear` events of views.
///
/// ## Usage
/// ```swift
/// let logAction: LoggerAction = .navigation
/// print("Logging action: \(logAction)")
/// ```
public enum LoggerAction {
  /// Logs the initialization (`init`) and deallocation (`deinit`) of a router.
  case routerLifecycle
  /// Logs when a route is displayed.
  case navigation(from: any Route, to: any Route, type: RoutingType)
  /// Logs actions related to navigation events, dismissals, and back navigation.
  case action
  /// Logs `onAppear` and `onDisappear` events of views.
  case viewLifecycle

  case context
}
