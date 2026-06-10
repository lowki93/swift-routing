//
//  RoutingSplitView.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 25/03/2025.
//

import SwiftUI

/// A `NavigationSplitView` container with its own `SplitRouter` for split-level navigation.
///
/// `RoutingSplitView` wraps SwiftUI's `NavigationSplitView` and injects a `SplitRouter`
/// into the environment for programmatic sheet/cover presentations and cross-column context passing.
///
/// Both sidebar and detail columns share the same `Destination` type. The sidebar is automatically
/// wrapped in a `RoutingView` driven by `sidebarRoot`.
///
/// ## Examples
/// ```swift
/// // 2-column, auto detail
/// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar, root: .home)
///
/// // 2-column, manual detail
/// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar) {
///   RoutingView(destination: AppRoute.self, root: .home)
/// }
///
/// // 3-column
/// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar) {
///   ContentView()
/// } detail: {
///   RoutingView(destination: AppRoute.self, root: .home)
/// }
///
/// // With column visibility binding
/// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar, root: .home, columnVisibility: $visibility)
/// ```
///
/// ## Accessing the SplitRouter
/// ```swift
/// @Environment(\.splitRouter) var splitRouter
///
/// splitRouter?.present(AppRoute.settings)
/// splitRouter?.add(context: ItemSelectedContext.self) { ctx in
///   selectedItem = ctx.item
/// }
/// ```
@MainActor
public struct RoutingSplitView<Destination: RouteDestination>: View {

  @Environment(\.router) private var parent
  private let columnVisibility: RoutingSpitViewType
  private let preferredCompactColumn: Binding<NavigationSplitViewColumn>
  private let destination: Destination.Type
  private let sidebarRoot: Destination.R

  public init(
    columnVisibility: RoutingSpitViewType,
    preferredCompactColumn: Binding<NavigationSplitViewColumn>,
    destination: Destination.Type,
    sidebarRoot: Destination.R,
  ) {
    self.destination = destination
    self.sidebarRoot = sidebarRoot
    self.columnVisibility = columnVisibility
    self.preferredCompactColumn = preferredCompactColumn
  }

  public var body: some View {
    Wrapped(
      splitRouter: SplitRouter(columVisibility: columnVisibility, root: AnyRoute(wrapped: sidebarRoot), parent: parent),
      preferredCompactColumn: preferredCompactColumn,
      destination: destination,
    )
  }

  private struct Wrapped: View {

    @StateObject var splitRouter: SplitRouter
    @Binding var preferredCompactColumn: NavigationSplitViewColumn
    let destination: Destination.Type

    var body: some View {
      navigationView
        .sheet($splitRouter.sheet, for: destination, onDismiss: {})
        .cover($splitRouter.cover, for: destination, onDismiss: {})
        .environment(\.splitRouter, splitRouter)
        .environment(\.currentRouter, splitRouter)
    }

    @ViewBuilder
    private var navigationView: some View {
      switch splitRouter.columVisibility {
      case .detailOnly:
        NavigationSplitView(
          columnVisibility: .constant(.detailOnly),
          preferredCompactColumn: $preferredCompactColumn
        ) {
          sidebar
        } detail: {
          detail
        }
      case .doubleColumn:
        NavigationSplitView(
          columnVisibility: .constant(.doubleColumn),
          preferredCompactColumn: $preferredCompactColumn
        ) {
          sidebar
        } content: {
          content
        } detail: {
          detail
        }
      }
    }

    @ViewBuilder
    private var sidebar: some View {
      if let sidebar = splitRouter.root.wrapped as? Destination.R {
        Destination[sidebar]
      }
    }

    @ViewBuilder
    private var content: some View {
      if let anyRoute = splitRouter.content, let root = anyRoute.wrapped as? Destination.R {
        Destination[root]
          .id(anyRoute.id)
      }
    }

    @ViewBuilder
    private var detail: some View {
      if let anyRoute = splitRouter.detail, let root = anyRoute.wrapped as? Destination.R {
        RoutingView(destination: destination, root: root)
          .id(anyRoute.id)
      }
    }
  }
}

public enum RoutingSpitViewType {
  case detailOnly
  case doubleColumn

  var navigationSplitViewVisibility: Binding<NavigationSplitViewVisibility> {
    switch self {
    case .detailOnly: .constant(.detailOnly)
    case .doubleColumn: .constant(.doubleColumn)
    }
  }
}
