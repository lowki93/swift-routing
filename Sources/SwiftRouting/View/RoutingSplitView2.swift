//
//  RoutingSplitView2.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 10/06/2026.
//

import SwiftUI

/// A `NavigationSplitView` container where each column is driven by a typed route factory.
///
/// The sidebar is always a fixed route. Content and detail columns are driven by typed,
/// hashable selections — each selection is mapped to a `Destination.R` route rendered
/// inside its own `RoutingView`, giving every column an independent navigation stack.
///
/// ## 2-column (sidebar + detail)
/// ```swift
/// RoutingSplitView2(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
///   AppRoute.players(type)
/// }
/// ```
///
/// ## 3-column (sidebar + content + detail)
/// ```swift
/// RoutingSplitView2(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
///   AppRoute.players(type)
/// } detail: { (player: Player) in
///   AppRoute.player(player)
/// }
/// ```
///
/// ## Setting the selection from the sidebar
/// ```swift
/// @Environment(\.router) var router
///
/// List(array, selection: router.detailBinding(as: PlayerType.self)) { item in
///   NavigationLink(item.label, value: item)
/// }
/// .onFirstAppear {
///   router.select(detail: array.first)
/// }
/// ```
@MainActor
public struct RoutingSplitView2<
  Destination: RouteDestination,
  ContentData: Hashable & Sendable,
  DetailData: Hashable & Sendable
>: View {

  @Environment(\.router) private var parent
  private let columnVisibility: Binding<NavigationSplitViewVisibility>?
  private let preferredCompactColumn: Binding<NavigationSplitViewColumn>
  private let destination: Destination.Type
  private let sidebarRoute: Destination.R
  private let contentRoute: ((ContentData) -> Destination.R)?
  private let detailRoute: ((DetailData) -> Destination.R)?

  private init(
    columnVisibility: Binding<NavigationSplitViewVisibility>?,
    preferredCompactColumn: Binding<NavigationSplitViewColumn>,
    destination: Destination.Type,
    sidebarRoute: Destination.R,
    contentRoute: ((ContentData) -> Destination.R)?,
    detailRoute: ((DetailData) -> Destination.R)?
  ) {
    self.columnVisibility = columnVisibility
    self.preferredCompactColumn = preferredCompactColumn
    self.destination = destination
    self.sidebarRoute = sidebarRoute
    self.contentRoute = contentRoute
    self.detailRoute = detailRoute
  }

  public var body: some View {
    Wrapped(
      router: Router(
        root: AnyRoute(wrapped: sidebarRoute),
        type: .split(sidebarRoute.name, hasContentColumn: contentRoute != nil),
        parent: parent
      ),
      columnVisibility: columnVisibility,
      preferredCompactColumn: preferredCompactColumn,
      destination: destination,
      sidebarRoute: sidebarRoute,
      contentRoute: contentRoute,
      detailRoute: detailRoute
    )
  }

  private struct Wrapped: View {

    @StateObject var router: Router
    @Environment(\.horizontalSizeClass) private var sizeClass
    let columnVisibility: Binding<NavigationSplitViewVisibility>?
    let preferredCompactColumn: Binding<NavigationSplitViewColumn>
    let destination: Destination.Type
    let sidebarRoute: Destination.R
    let contentRoute: ((ContentData) -> Destination.R)?
    let detailRoute: ((DetailData) -> Destination.R)?

    var body: some View {
      splitView
        .sheet($router.sheet, for: destination, onDismiss: {})
        .cover($router.cover, for: destination, onDismiss: {})
        .environment(\.router, router)
        .environment(\.currentRouter, router)
        .onChange(of: sizeClass) { [weak router] new in
          router?.isCompact = new == .compact
        }
    }

    @ViewBuilder
    private var splitView: some View {
      if let columnVisibility, let contentRoute {
        NavigationSplitView(columnVisibility: columnVisibility, preferredCompactColumn: preferredCompactColumn) {
          sidebar
        } content: {
          if let selection = router.contentSelection as? ContentData {
            Destination[contentRoute(selection)]
              .id(selection)
          }
        } detail: {
          detailColumn
        }
      } else {
        NavigationSplitView(preferredCompactColumn: preferredCompactColumn) {
          sidebar
        } detail: {
          detailColumn
        }
      }
    }

    private var sidebar: some View {
      Destination[sidebarRoute]
    }

    @ViewBuilder
    private var detailColumn: some View {
      if let selection = router.detailSelection as? DetailData, let detailRoute {
        RoutingView(destination: destination, root: detailRoute(selection))
          .id(selection)
      }
    }
  }
}

// MARK: - 2-column init

extension RoutingSplitView2 where ContentData == Never {

  /// Creates a 2-column split view where the sidebar drives the detail column directly.
  ///
  /// - Parameters:
  ///   - destination: Route destination type shared by all columns.
  ///   - sidebar: The route shown in the sidebar column.
  ///   - detail: Closure mapping a `DetailData` selection to the route shown in the detail column.
  public init(
    preferredCompactColumn: Binding<NavigationSplitViewColumn> = .constant(.sidebar),
    destination: Destination.Type,
    sidebar: Destination.R,
    detail: @escaping (DetailData) -> Destination.R
  ) {
    self.init(
      columnVisibility: nil,
      preferredCompactColumn: preferredCompactColumn,
      destination: destination,
      sidebarRoute: sidebar,
      contentRoute: nil,
      detailRoute: detail
    )
  }
}

// MARK: - 3-column init

extension RoutingSplitView2 {

  /// Creates a 3-column split view where the sidebar drives content and content drives detail.
  ///
  /// - Parameters:
  ///   - destination: Route destination type shared by all columns.
  ///   - sidebar: The route shown in the sidebar column.
  ///   - content: Closure mapping a `ContentData` selection to the route shown in the content column.
  ///   - detail: Closure mapping a `DetailData` selection to the route shown in the detail column.
  public init(
    columnVisibility: Binding<NavigationSplitViewVisibility> = .constant(.all),
    preferredCompactColumn: Binding<NavigationSplitViewColumn> = .constant(.sidebar),
    destination: Destination.Type,
    sidebar: Destination.R,
    content: @escaping (ContentData) -> Destination.R,
    detail: @escaping (DetailData) -> Destination.R
  ) {
    self.init(
      columnVisibility: Optional(columnVisibility),
      preferredCompactColumn: preferredCompactColumn,
      destination: destination,
      sidebarRoute: sidebar,
      contentRoute: content,
      detailRoute: detail
    )
  }
}
