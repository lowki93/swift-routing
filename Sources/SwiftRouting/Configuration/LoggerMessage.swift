//
//  LoggerMessage.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import Foundation

/// Represents the type of action logged by the router.
///
/// `LoggerMessage` defines various categories of events that can be tracked within the navigation system.
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
/// let logAction: LoggerMessage = .navigation
/// print("Logging action: \(logAction)")
/// ```
public enum LoggerMessage {
  /// Log the `initialization` of a router
  case create(from: BaseRouter?)
  /// Log deallocation `deinit` of a router.
  case delete
  /// Log when a new route is displayed.
  case navigation(from: any Route, to: any Route, type: RoutingType)
  /// Log actions related to navigation events, dismissals, and back navigation.
  case action(Action)
  /// Log `onAppear` route.
  case onAppear(any Route)
  /// Log `onDisappear` route
  case onDisappear(any Route)
  /// Log `context` send from which `Route`
  case context(any RouteContext, from: any Route)
}

public extension LoggerMessage {
  enum Action {
    case popToRoot
    case close
    case back(count: Int? = nil)
    case closeChildren(BaseRouter)
    case changeTab(any TabRoute)
  }
}
