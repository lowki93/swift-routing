//
//  SplitRouter.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/03/2025.
//

import Foundation

/// A router managing sheet, cover, and context at the `RoutingSplitView` level.
///
/// `SplitRouter` enables programmatic modal presentations over the entire split view
/// and supports context passing between sidebar and detail columns.
///
/// Unlike `Router`, `SplitRouter` does not manage a navigation stack — it focuses
/// exclusively on presentations (sheet, cover) and cross-column contexts.
///
/// ## Usage
/// ```swift
/// splitRouter.present(AppRoute.settings)
/// splitRouter.cover(AppRoute.onboarding)
///
/// splitRouter.add(context: ItemSelectedContext.self) { [weak self] ctx in
///   self?.selectedItem = ctx.item
/// }
/// ```
///
/// The `SplitRouter` instance is accessible from the environment inside a `RoutingSplitView`:
/// ```swift
/// @Environment(\.splitRouter) var splitRouter
/// ```
public final class SplitRouter: BaseRouter, @unchecked Sendable {

  @Published internal var sheet: AnyRoute? {
    didSet {
      guard oldValue != sheet else { return }
      present.send((sheet != nil, self))
    }
  }
  @Published internal var cover: AnyRoute? {
    didSet {
      guard oldValue != cover else { return }
      present.send((cover != nil, self))
    }
  }

  init(parent: BaseRouter) {
    super.init(configuration: parent.configuration, parent: parent)
    parent.addChild(self)
  }
}

// MARK: - Presentation

public extension SplitRouter {

  /// Presents a route as a modal sheet over the entire split view.
  ///
  /// - Parameters:
  ///   - destination: The `Route` to present as a sheet.
  ///   - withStack: If `true`, the sheet includes a navigation stack. Defaults to `true`.
  ///
  /// ```swift
  /// splitRouter.present(AppRoute.settings)
  /// ```
  @MainActor func present(_ destination: some Route, withStack: Bool = true) {
    log(.navigation(from: DefaultRoute.main, to: destination, type: .sheet(withStack: withStack)))
    sheet = AnyRoute(wrapped: destination, inStack: withStack)
  }

  /// Presents a route as a full-screen cover over the entire split view.
  ///
  /// - Parameter destination: The `Route` to present as a cover.
  ///
  /// ```swift
  /// splitRouter.cover(AppRoute.onboarding)
  /// ```
  @MainActor func cover(_ destination: some Route) {
    log(.navigation(from: DefaultRoute.main, to: destination, type: .cover))
    cover = AnyRoute(wrapped: destination)
  }
}

// MARK: - Context

public extension SplitRouter {

  /// Registers a context observer for a specific `RouteContext` type.
  ///
  /// Use this to observe context events sent from sidebar or detail columns.
  ///
  /// ```swift
  /// splitRouter.add(context: ItemSelectedContext.self) { [weak self] ctx in
  ///   self?.selectedItem = ctx.item
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - object: The `RouteContext` type to observe.
  ///   - perform: A closure executed when the context is triggered.
  @MainActor func add<R: RouteContext>(context object: R.Type, perform: @escaping (R) -> Void) {
    let (inserted, element) = contexts.insert(
      RouterContext(
        baseRouter: self,
        routerContext: object,
        action: { [perform] in
          guard let value = $0 as? R else { return }
          perform(value)
        }
      )
    )
    if inserted {
      log(.context(.add(element.route, context: element.routerContext)))
    }
  }

  /// Removes all context observers for a specific `RouteContext` type.
  ///
  /// - Parameter object: The `RouteContext` type to stop observing.
  ///
  /// ```swift
  /// splitRouter.remove(context: ItemSelectedContext.self)
  /// ```
  @MainActor func remove<R: RouteContext>(context object: R.Type) {
    for element in contexts.all(for: object) {
      contexts.remove(element)
      log(.context(.remove(element.route, context: element.routerContext)))
    }
  }

  /// Executes a context across the router hierarchy.
  ///
  /// Propagates the context to all matching observers in parent routers and in the current split router.
  ///
  /// - Parameter value: The `RouteContext` to execute.
  ///
  /// ```swift
  /// splitRouter.context(ItemSelectedContext(item: item))
  /// ```
  @MainActor func context(_ value: some RouteContext) {
    let termination = Swift.type(of: value)
    var current = parent
    while let router = current {
      router.contexts.all(for: termination).forEach { $0.execute(value) }
      current = router.parent
    }
    contexts.all(for: termination).forEach { $0.execute(value) }
  }
}
