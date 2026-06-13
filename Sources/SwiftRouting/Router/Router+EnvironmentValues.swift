//
//  Router+EnvironmentValues.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 26/01/2025.
//

import SwiftUI

extension EnvironmentValues {
  /// Adds a `Router` instance to the environment values.
  ///
  /// This allows access to the router from anywhere in the app using:
  /// ```swift
  /// @Environment(\.router) var router
  /// ```
  ///
  /// This provides access to the current router within the navigation stack.
  @Entry public var router: Router = .defaultRouter

  /// Adds a `TabRouter` instance to the environment values.
  ///
  /// This allows access to the tabRouter from anywhere in the app using:
  /// ```swift
  /// @Environment(\.tabRouter) var tabRouter
  /// ```
  ///
  /// This provides access to the current router within the navigation stack.
  @Entry public var tabRouter: TabRouter?

  /// Adds a `SplitRouter` instance to the environment values.
  ///
  /// This allows access to the splitRouter from anywhere in the app using:
  /// ```swift
  /// @Environment(\.splitRouter) var splitRouter
  /// ```
  ///
  /// This provides access to the split-level router for sheet, cover, and context management.
  @Entry public var splitRouter: SplitRouter?

  /// Adds a `SplitRouter2` instance to the environment values.
  ///
  /// This allows access to the split router from anywhere inside a `RoutingSplitView2`:
  /// ```swift
  /// @Environment(\.splitRouter2) var splitRouter
  ///
  /// splitRouter?.select(detail: PlayerType.footballer)
  /// ```
  @Entry public var splitRouter2: SplitRouter2?

  @Entry public var currentRouter: BaseRouter?
}
