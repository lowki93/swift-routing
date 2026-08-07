//
//  LoggerMessage.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import Foundation

/// Defines the types of loggable events within the routing and navigation system.
///
/// `LoggerMessage` provides a comprehensive set of events for tracking router lifecycle,
/// navigation actions, view appearances, and context transmissions. Use these messages
/// with a custom `Configuration` logger for debugging, analytics, or monitoring.
///
/// ## Overview
///
/// The routing system automatically generates these messages at key points:
/// - Router creation and destruction
/// - Navigation between routes (push, present, cover)
/// - View lifecycle events (appear, disappear)
/// - User-initiated actions (back, close, tab changes)
/// - Context observer lifecycle and execution
///
/// ## Example
///
/// Configure a custom logger to handle these messages:
///
/// ```swift
/// let config = Configuration(logger: { message in
///   switch message.message {
///   case .navigation(let from, let to, let type):
///     print("Navigate: \(from.name) → \(to.name) via \(type)")
///   case .action(.back):
///     print("User navigated back")
///   default:
///     break
///   }
/// })
/// ```
public enum LoggerMessage {
  /// Logs the creation of a router instance.
  ///
  /// - Parameters:
  ///   - from: The parent router that created this router, or `nil` for root routers.
  ///   - configuration: The configuration used to initialize the router.
  case create(from: BaseRouter?, Configuration?)

  /// Logs the deallocation of a router instance.
  ///
  /// This event is triggered when a router is deallocated, typically when
  /// a presented view is dismissed or a tab is removed.
  case delete

  /// Logs a navigation action between routes.
  ///
  /// - Parameters:
  ///   - from: The source route before navigation.
  ///   - to: The destination route after navigation.
  ///   - type: The type of navigation (push, sheet, cover, root).
  case navigation(from: any Route, to: any Route, type: RoutingType)

  /// Logs a user-initiated navigation action.
  ///
  /// See ``Action`` for the list of available actions.
  case action(Action)

  /// Logs when a route's view appears on screen.
  ///
  /// - Parameter route: The route whose view triggered `onAppear`.
  case onAppear(any Route)

  /// Logs when a route's view disappears from screen.
  ///
  /// - Parameter route: The route whose view triggered `onDisappear`.
  case onDisappear(any Route)

  /// Logs a context-related event.
  ///
  /// See ``Context`` for the list of context events (add, execute, remove).
  case context(Context)

  /// Logs a routing error.
  ///
  /// - Parameter error: The ``RouterError`` that occurred.
  case error(RouterError)
}

extension LoggerMessage {
  /// Whether this message should notify ``Configuration/events`` observers, such as
  /// ``SwiftUICore/View/printRouterOnChange()``.
  ///
  /// `.onAppear`/`.onDisappear` are excluded: they fire right after the `.navigation`
  /// event that caused the appearance in the first place, so notifying for both would just
  /// duplicate the same signal without adding new information. `.error` is excluded since
  /// it doesn't reflect a change to the router tree. `.action` and `.context` delegate to
  /// their own nested `shouldTriggerEvent`, since only some of their cases are worth it.
  var shouldTriggerEvent: Bool {
    switch self {
    case .onAppear, .onDisappear, .error:
      false
    case .create, .delete, .navigation:
      true
    case let .action(action):
      action.shouldTriggerEvent
    case let .context(context):
      context.shouldTriggerEvent
    }
  }
}

public extension LoggerMessage {
  /// Represents user-initiated navigation actions that can be logged.
  ///
  /// These actions are triggered by programmatic navigation calls
  /// such as `back()`, `close()`, or `popToRoot()`.
  enum Action {
    /// Logs a navigation reset to the root route.
    ///
    /// Triggered when `popToRoot()` is called on a router.
    case popToRoot

    /// Logs the dismissal of a presented router.
    ///
    /// Triggered when `close()` is called on a sheet or cover.
    case close

    /// Logs a backward navigation in the stack.
    ///
    /// - Parameter count: The number of routes removed from the stack.
    ///   `nil` indicates a single back navigation.
    case back(count: Int? = nil)

    /// Logs the dismissal of all child routers.
    ///
    /// - Parameter router: The parent router whose children were closed.
    case closeChildren(BaseRouter)

    /// Logs a tab selection change.
    ///
    /// - Parameter tab: The newly selected tab route.
    case changeTab(any TabRoute)

    /// `.changeTab` activates a different tab's subtree, and `.back`/`.popToRoot` change
    /// which route is current, both worth re-printing. `.close`/`.closeChildren` are
    /// excluded since they're followed by the closed router's own `.delete` once it
    /// deinitializes, so notifying here too would just duplicate that signal.
    var shouldTriggerEvent: Bool {
      switch self {
      case .close, .closeChildren:
        false
      case .changeTab, .back, .popToRoot:
        true
      }
    }
  }
}

public extension LoggerMessage {
  /// Represents context-related events that can be logged.
  ///
  /// Use these cases to track the lifecycle of `RouteContext` observers:
  /// when they are registered, triggered, or removed.
  enum Context {
    /// Logs when a context observer is registered on a route.
    ///
    /// - Parameters:
    ///   - route: The route where the context observer was added.
    ///   - context: The type of `RouteContext` being observed.
    case add(any Route, context: any RouteContext.Type)

    /// Logs when a context is executed/triggered.
    ///
    /// - Parameters:
    ///   - context: The `RouteContext` instance that was triggered.
    ///   - from: The route from which the context was sent.
    case execute(any RouteContext, from: any Route)

    /// Logs when a context observer is removed from a route.
    ///
    /// - Parameters:
    ///   - route: The route where the context observer was removed.
    ///   - context: The type of `RouteContext` that was being observed.
    case remove(any Route, context: any RouteContext.Type)

    /// `.add`/`.remove` change which contexts are registered. `.execute` only invokes an
    /// already-registered observer's closure -- nothing about the tree itself changes.
    var shouldTriggerEvent: Bool {
      switch self {
      case .execute:
        false
      case .add, .remove:
        true
      }
    }
  }
}
