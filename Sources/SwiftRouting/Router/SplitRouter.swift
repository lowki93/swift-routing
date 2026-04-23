//
//  SplitRouter.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/03/2025.
//

import SwiftUI

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

  @Published public var columVisibility: RoutingSpitViewType
  @Published public var content: AnyRoute?
  @Published public var detail: AnyRoute?

  public override var currentRoute: AnyRoute {
    detail ?? content ?? root
  }

  init(columVisibility: RoutingSpitViewType, root: AnyRoute, parent: BaseRouter) {
    self.columVisibility = columVisibility
    super.init(configuration: parent.configuration, root: root, parent: parent)
    parent.addChild(self)
  }

  func route(content route: some Route) {
    log(.navigation(from: currentRoute.wrapped, to: route, type: .push))

    switch columVisibility {
    case .detailOnly:
      self.route(detail: route)
    case .doubleColumn:
      detail = nil
      content = AnyRoute(wrapped: route)
    }
  }

  func route(detail route: some Route) {
    log(.navigation(from: currentRoute.wrapped, to: route, type: .push))
    detail = AnyRoute(wrapped: route)
  }
}

protocol SplitRouterModel: BaseRouterModel, ContextModel, PresentationModel {

  func route(content route: some Route)
  func route(detail route: some Route)

}
