//
//  RouteContext.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/3/25.
//

/// A type that can be used to pass data between routes and trigger navigation flow completions.
///
/// `RouteContext` is a typealias combining `Hashable` and `Sendable`, allowing any conforming type
/// to be safely passed across isolation boundaries and used as a key for context observers.
///
/// ## Overview
///
/// Use `RouteContext` to:
/// - Pass data back from a child route to a parent route
/// - Signal the completion of a navigation flow
/// - Trigger actions across the router hierarchy
///
/// ## Example
///
/// Define a context type to pass user selection data:
///
/// ```swift
/// struct UserSelectionContext: RouteContext {
///   let selectedUser: User
/// }
/// ```
///
/// Register a context observer in the parent view:
///
/// ```swift
/// router.add(context: UserSelectionContext.self) { [weak self] context in
///   self?.selectedUser = context.selectedUser
/// }
/// ```
///
/// Trigger the context from a child route:
///
/// ```swift
/// // Just execute the context (observers are notified)
/// router.context(UserSelectionContext(selectedUser: user))
///
/// // Or terminate the flow (execute context + navigate back)
/// router.terminate(UserSelectionContext(selectedUser: user))
/// ```
///
/// > Warning: When using `add(context:perform:)`, capture references with `[weak self]`
/// > to prevent memory leaks.
///
/// ## Topics
///
/// ### Registering Observers
/// - ``RouterModel/add(context:perform:)``
/// - ``RouterModel/remove(context:)``
///
/// ### Triggering Contexts
/// - ``RouterModel/context(_:)``
/// - ``RouterModel/terminate(_:)``
public typealias RouteContext = Hashable & Sendable
