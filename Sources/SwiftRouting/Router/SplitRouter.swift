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
public final class SplitRouter: PresentableRouter, @unchecked Sendable {

  init(parent: BaseRouter) {
    super.init(configuration: parent.configuration, parent: parent)
    parent.addChild(self)
  }
}
