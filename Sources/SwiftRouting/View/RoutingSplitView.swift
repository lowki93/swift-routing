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
/// The sidebar column is automatically wrapped in a `RoutingView` driven by `SidebarDestination`.
/// The detail column can be provided manually or auto-wrapped via a convenience initializer.
///
/// ## Examples
/// ```swift
/// // 2-column, auto detail
/// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: DetailRoute.self, root: .home)
///
/// // 2-column, manual detail
/// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: AppRoute.self) {
///   RoutingView(destination: DetailRoute.self, root: .home)
/// }
///
/// // 3-column
/// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: AppRoute.self) {
///   ContentView()
/// } detail: {
///   RoutingView(destination: DetailRoute.self, root: .home)
/// }
///
/// // With column visibility binding
/// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: DetailRoute.self, root: .home, columnVisibility: $visibility)
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
public struct RoutingSplitView<SidebarDestination: RouteDestination, Destination: RouteDestination, Content: View, Detail: View>: View {

  @Environment(\.router) private var parent
  private let sidebarDestination: SidebarDestination.Type
  private let sidebarRoot: SidebarDestination.R
  private let destination: Destination.Type
  private let columnVisibility: Binding<NavigationSplitViewVisibility>?
  private let content: Content?
  private let detail: Detail

  init(
    sidebarDestination: SidebarDestination.Type,
    sidebarRoot: SidebarDestination.R,
    destination: Destination.Type,
    columnVisibility: Binding<NavigationSplitViewVisibility>?,
    content: Content?,
    detail: Detail
  ) {
    self.sidebarDestination = sidebarDestination
    self.sidebarRoot = sidebarRoot
    self.destination = destination
    self.columnVisibility = columnVisibility
    self.content = content
    self.detail = detail
  }

  public var body: some View {
    Wrapped(
      splitRouter: SplitRouter(parent: parent),
      sidebarDestination: sidebarDestination,
      sidebarRoot: sidebarRoot,
      destination: destination,
      columnVisibility: columnVisibility,
      content: content,
      detail: detail
    )
  }

  private struct Wrapped: View {

    @StateObject var splitRouter: SplitRouter
    let sidebarDestination: SidebarDestination.Type
    let sidebarRoot: SidebarDestination.R
    let destination: Destination.Type
    let columnVisibility: Binding<NavigationSplitViewVisibility>?
    let content: Content?
    let detail: Detail

    var body: some View {
      navigationView
        .sheet($splitRouter.sheet, for: destination, onDismiss: {})
        .cover($splitRouter.cover, for: destination, onDismiss: {})
        .environment(\.splitRouter, splitRouter)
    }

    @ViewBuilder
    private var navigationView: some View {
      let sidebar = RoutingView(destination: sidebarDestination, root: sidebarRoot)
      if let content {
        if let visibility = columnVisibility {
          NavigationSplitView(columnVisibility: visibility) { sidebar } content: { content } detail: { detail }
        } else {
          NavigationSplitView { sidebar } content: { content } detail: { detail }
        }
      } else {
        if let visibility = columnVisibility {
          NavigationSplitView(columnVisibility: visibility) { sidebar } detail: { detail }
        } else {
          NavigationSplitView { sidebar } detail: { detail }
        }
      }
    }
  }
}

// MARK: - 2-column (manual detail)

extension RoutingSplitView where Content == EmptyView {

  /// Creates a 2-column split view with a route-driven sidebar and a custom detail column.
  ///
  /// - Parameters:
  ///   - sidebarDestination: The `RouteDestination` type for the sidebar column.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - detail: A view builder for the detail column. Typically wraps a `RoutingView`.
  ///
  /// ```swift
  /// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: AppRoute.self) {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    sidebarDestination: SidebarDestination.Type,
    sidebarRoot: SidebarDestination.R,
    destination: Destination.Type,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(sidebarDestination: sidebarDestination, sidebarRoot: sidebarRoot, destination: destination, columnVisibility: nil, content: nil, detail: detail())
  }

  /// Creates a 2-column split view with a route-driven sidebar, a custom detail column, and column visibility control.
  ///
  /// - Parameters:
  ///   - sidebarDestination: The `RouteDestination` type for the sidebar column.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///   - detail: A view builder for the detail column. Typically wraps a `RoutingView`.
  ///
  /// ```swift
  /// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: AppRoute.self, columnVisibility: $visibility) {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    sidebarDestination: SidebarDestination.Type,
    sidebarRoot: SidebarDestination.R,
    destination: Destination.Type,
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(sidebarDestination: sidebarDestination, sidebarRoot: sidebarRoot, destination: destination, columnVisibility: columnVisibility, content: nil, detail: detail())
  }
}

// MARK: - 2-column (auto detail)

extension RoutingSplitView where Content == EmptyView, Detail == RoutingView<Destination, EmptyView> {

  /// Creates a 2-column split view where both sidebar and detail columns are automatically wrapped in a `RoutingView`.
  ///
  /// - Parameters:
  ///   - sidebarDestination: The `RouteDestination` type for the sidebar column.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - destination: The `RouteDestination` type for the detail column and split-level presentations.
  ///   - root: The initial route displayed in the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: DetailRoute.self, root: .home)
  /// ```
  public init(
    sidebarDestination: SidebarDestination.Type,
    sidebarRoot: SidebarDestination.R,
    destination: Destination.Type,
    root: Destination.R
  ) {
    self.init(
      sidebarDestination: sidebarDestination,
      sidebarRoot: sidebarRoot,
      destination: destination,
      columnVisibility: nil,
      content: nil,
      detail: RoutingView(destination: destination, root: root)
    )
  }

  /// Creates a 2-column split view with auto-managed sidebar and detail columns, and column visibility control.
  ///
  /// - Parameters:
  ///   - sidebarDestination: The `RouteDestination` type for the sidebar column.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - destination: The `RouteDestination` type for the detail column and split-level presentations.
  ///   - root: The initial route displayed in the detail column.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///
  /// ```swift
  /// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: DetailRoute.self, root: .home, columnVisibility: $visibility)
  /// ```
  public init(
    sidebarDestination: SidebarDestination.Type,
    sidebarRoot: SidebarDestination.R,
    destination: Destination.Type,
    root: Destination.R,
    columnVisibility: Binding<NavigationSplitViewVisibility>
  ) {
    self.init(
      sidebarDestination: sidebarDestination,
      sidebarRoot: sidebarRoot,
      destination: destination,
      columnVisibility: columnVisibility,
      content: nil,
      detail: RoutingView(destination: destination, root: root)
    )
  }
}

// MARK: - 3-column

extension RoutingSplitView {

  /// Creates a 3-column split view with a route-driven sidebar, a content column, and a detail column.
  ///
  /// - Parameters:
  ///   - sidebarDestination: The `RouteDestination` type for the sidebar column.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - content: A view builder for the content (middle) column.
  ///   - detail: A view builder for the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: AppRoute.self) {
  ///   ContentView()
  /// } detail: {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    sidebarDestination: SidebarDestination.Type,
    sidebarRoot: SidebarDestination.R,
    destination: Destination.Type,
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(sidebarDestination: sidebarDestination, sidebarRoot: sidebarRoot, destination: destination, columnVisibility: nil, content: content(), detail: detail())
  }

  /// Creates a 3-column split view with a route-driven sidebar, column visibility control, a content column, and a detail column.
  ///
  /// - Parameters:
  ///   - sidebarDestination: The `RouteDestination` type for the sidebar column.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///   - content: A view builder for the content (middle) column.
  ///   - detail: A view builder for the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(sidebarDestination: SidebarRoute.self, sidebarRoot: .list, destination: AppRoute.self, columnVisibility: $visibility) {
  ///   ContentView()
  /// } detail: {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    sidebarDestination: SidebarDestination.Type,
    sidebarRoot: SidebarDestination.R,
    destination: Destination.Type,
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(sidebarDestination: sidebarDestination, sidebarRoot: sidebarRoot, destination: destination, columnVisibility: columnVisibility, content: content(), detail: detail())
  }
}
