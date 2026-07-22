//
//  RoutingSplitView.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 10/06/2026.
//

import SwiftUI

/// A type-safe `NavigationSplitView` container driven by typed route factories.
///
/// `RoutingSplitView` wraps SwiftUI's `NavigationSplitView` and ties each column
/// to a ``RouteDestination``. The sidebar is a fixed route; content and detail columns
/// are derived from typed, `Hashable` selections — every selection is resolved through
/// a factory closure to a ``RouteDestination/R`` route and rendered inside its own
/// `RoutingView`, giving each column an independent navigation stack.
///
/// A split-type ``Router`` is created automatically and injected into the environment
/// via `@Environment(\.router)`. Access it in any column view to drive selections or
/// present modals:
///
/// ```swift
/// @Environment(\.router) var router
///
/// router.select(detail: player)          // show player in the detail column
/// router.present(AppRoute.settings)      // present a sheet from the split level
/// ```
///
/// ## Compact mode (iPhone)
///
/// On iPhone, `NavigationSplitView` collapses into a single-column stack. Use
/// `router.isCompact` to skip auto-selection and let the user tap to navigate:
///
/// ```swift
/// .onFirstAppear {
///   guard !router.isCompact else { return }
///   router.select(detail: items.first)
/// }
/// ```
///
/// ## 2-column layout (sidebar + detail)
///
/// ```swift
/// RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
///   AppRoute.players(type)
/// }
/// ```
///
/// ## 3-column layout (sidebar + content + detail)
///
/// ```swift
/// RoutingSplitView(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
///   AppRoute.players(type)
/// } detail: { (player: Player) in
///   AppRoute.player(player)
/// }
/// ```
///
/// ## Driving selections from the sidebar
///
/// Use ``Router/detailBinding(as:)`` or ``Router/contentBinding(as:)`` to wire a
/// `List` selection binding, or call ``Router/select(detail:)`` programmatically:
///
/// ```swift
/// struct SidebarScreen: View {
///   @Environment(\.router) var router
///   let items: [PlayerType] = PlayerType.allCases
///
///   var body: some View {
///     List(items, selection: router.detailBinding(as: PlayerType.self)) { item in
///       NavigationLink(item.label, value: item)
///     }
///     .onFirstAppear {
///       guard !router.isCompact else { return }
///       router.select(detail: items.first)
///     }
///   }
/// }
/// ```
@MainActor
public struct RoutingSplitView<
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
        parent: parent,
        detailRouteFactory: detailRoute.map { factory in
          { sel in (sel as? DetailData).map { AnyRoute(wrapped: factory($0)) } }
        },
        contentRouteFactory: contentRoute.map { factory in
          { sel in (sel as? ContentData).map { AnyRoute(wrapped: factory($0)) } }
        }
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

    @Environment(\.horizontalSizeClass) private var sizeClass
    @StateObject var router: Router
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
        .onChange(of: sizeClass) { [weak router] in
          router?.isCompact = sizeClass == .compact
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
        NavigationStack(path: $router.path) {
          Destination[detailRoute(selection)]
            .navigationDestination(destination)
        }
          .id(selection)
      }
    }
  }
}

// MARK: - 2-column init

extension RoutingSplitView where ContentData == Never {

  /// Creates a 2-column split view (sidebar + detail).
  ///
  /// The sidebar shows a fixed route. The detail column is updated whenever
  /// `router.select(detail:)` is called or the `List` selection binding changes.
  ///
  /// On iPhone the split view collapses to a single stack; `router.isCompact` reflects
  /// this state so you can skip programmatic auto-selection when appropriate.
  ///
  /// ```swift
  /// RoutingSplitView(
  ///   preferredCompactColumn: $compactColumn,
  ///   destination: AppRoute.self,
  ///   sidebar: .sidebar
  /// ) { (type: PlayerType) in
  ///   AppRoute.players(type)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - preferredCompactColumn: Controls which column is shown when the split view is
  ///     in compact mode. Defaults to `.sidebar`. Pass `.detail` to open directly on
  ///     the detail column (e.g. after a programmatic selection).
  ///   - destination: The ``RouteDestination`` type shared by all columns.
  ///   - sidebar: The route rendered in the sidebar column.
  ///   - detail: Closure mapping a `DetailData` value to the route shown in the detail column.
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

extension RoutingSplitView {

  /// Creates a 3-column split view (sidebar + content + detail).
  ///
  /// The sidebar drives the content column via `router.select(content:)`, and the
  /// content column drives the detail column via `router.select(detail:)`.
  /// Each column renders inside its own `RoutingView` with an independent navigation stack.
  ///
  /// ```swift
  /// RoutingSplitView(
  ///   columnVisibility: $columnVisibility,
  ///   destination: AppRoute.self,
  ///   sidebar: .sidebar
  /// ) { (type: PlayerType) in
  ///   AppRoute.players(type)
  /// } detail: { (player: Player) in
  ///   AppRoute.player(player)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - columnVisibility: Controls which columns are visible (`.all`, `.doubleColumn`,
  ///     `.detailOnly`). Defaults to `.all`.
  ///   - preferredCompactColumn: Controls which column is shown in compact mode.
  ///     Defaults to `.sidebar`.
  ///   - destination: The ``RouteDestination`` type shared by all columns.
  ///   - sidebar: The route rendered in the sidebar column.
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
