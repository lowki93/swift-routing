//
//  ContextModel.swift
//  swift-routing
//
//  Created by Kévin Budain on 25/03/26.
//

import Foundation

/// Defines context observation capabilities for router types.
///
/// `ContextModel` provides the ability to register, remove, and dispatch
/// ``RouteContext`` observers. It is implemented by ``BaseRouter`` and
/// inherited by all concrete router types, including ``Router`` and future
/// router types such as `SplitRouter`.
///
/// Use these methods to pass data back from child routes or to react to
/// navigation flow completions.
public protocol ContextModel {

  /// Registers a context observer for a specific ``RouteContext`` type.
  ///
  /// The closure is executed whenever a matching context is dispatched via
  /// ``context(_:)`` or ``RouterModel/terminate(_:)``.
  ///
  /// > **Warning:** Capture class instances `[weak]` inside `perform` to
  /// > avoid retain cycles.
  ///
  /// - Parameters:
  ///   - object: The ``RouteContext`` type to observe.
  ///   - perform: A closure executed when the context is triggered.
  func add<R: RouteContext>(context object: R.Type, perform: @escaping (R) -> Void)

  /// Removes context observers for a specific ``RouteContext`` type on the current route.
  ///
  /// Only observers registered on the router's current route are removed.
  ///
  /// - Parameter object: The ``RouteContext`` type to stop observing.
  func remove<R: RouteContext>(context object: R.Type)

  /// Dispatches a context value across the entire router hierarchy.
  ///
  /// Searches for matching observers in all parent routers (from root to
  /// direct parent) and in the current router, then executes them.
  ///
  /// - Parameter value: The ``RouteContext`` to dispatch.
  func context(_ value: some RouteContext)
}
