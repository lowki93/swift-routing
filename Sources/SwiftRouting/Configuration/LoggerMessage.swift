//
//  LoggerMessage.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import Foundation

///
/// `LoggerMessage` defines the types of loggable events within the routing/navigation system.
///
/// Use this enum to track lifecycle events, navigation actions, view appearances, and route context transmissions for analytics or debugging.
public enum LoggerMessage {
  /// Logs the initialization (creation) of a router instance.
  case create(from: BaseRouter?, Configuration?)
  /// Logs the deallocation (destruction) of a router instance.
  case delete
  /// Logs a navigation action, including the source and destination routes and the type of navigation.
  case navigation(from: any Route, to: any Route, type: RoutingType)
  /// Logs a navigation-related user action (see `Action` enum for details).
  case action(Action)
  /// Logs when a route/view appears (onAppear event).
  case onAppear(any Route)
  /// Logs when a route/view disappears (onDisappear event).
  case onDisappear(any Route)
  /// Logs that context has been sent from a specific route.
  case context(Context)
}

public extension LoggerMessage {
  /// Represents navigation-related user actions that can be logged.
  enum Action {
    /// Logs an action to pop navigation to the root route.
    case popToRoot
    /// Logs an action to close the current view or route.
    case close
    /// Logs a back navigation action (optionally multiple steps if count is provided).
    case back(count: Int? = nil)
    /// Logs the closure of all child routes associated with a specific router.
    case closeChildren(BaseRouter)
    /// Logs a tab change action to a specified tab route.
    case changeTab(any TabRoute)
  }
}

public extension LoggerMessage {
  enum Context {
    case add(any Route, context: any RouteContext.Type)
    case execute(any RouteContext, from: any Route)
    case remove(any Route, context: any RouteContext.Type)
  }
}
