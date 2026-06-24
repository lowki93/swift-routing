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
  /// Inside a `RoutingSplitView2`, `router` is the split router — call
  /// `router.select(detail:)` or `router.select(content:)` to drive column selections.
  @Entry public var router: Router = .defaultRouter

  /// Adds a `TabRouter` instance to the environment values.
  ///
  /// This allows access to the tabRouter from anywhere in the app using:
  /// ```swift
  /// @Environment(\.tabRouter) var tabRouter
  /// ```
  @Entry public var tabRouter: TabRouter?

  @Entry public var currentRouter: BaseRouter?
}
