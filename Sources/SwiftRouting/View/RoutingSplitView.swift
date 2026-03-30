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
public struct RoutingSplitView<Destination: RouteDestination, Content: View, Detail: View>: View {

  @Environment(\.router) private var parent
  private let destination: Destination.Type
  private let sidebarRoot: Destination.R
  private let columnVisibility: Binding<NavigationSplitViewVisibility>?
  private let content: Content?
  private let detail: Detail

  init(
    destination: Destination.Type,
    sidebarRoot: Destination.R,
    columnVisibility: Binding<NavigationSplitViewVisibility>?,
    content: Content?,
    detail: Detail
  ) {
    self.destination = destination
    self.sidebarRoot = sidebarRoot
    self.columnVisibility = columnVisibility
    self.content = content
    self.detail = detail
  }

  public var body: some View {
    Wrapped(
      splitRouter: SplitRouter(parent: parent),
      destination: destination,
      sidebarRoot: sidebarRoot,
      columnVisibility: columnVisibility,
      content: content,
      detail: detail
    )
  }

  private struct Wrapped: View {

    @StateObject var splitRouter: SplitRouter
    let destination: Destination.Type
    let sidebarRoot: Destination.R
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
      let sidebar = RoutingView(destination: destination, root: sidebarRoot)
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
  ///   - destination: The `RouteDestination` type shared by both columns and split-level presentations.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - detail: A view builder for the detail column. Typically wraps a `RoutingView`.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar) {
  ///   RoutingView(destination: AppRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    sidebarRoot: Destination.R,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, sidebarRoot: sidebarRoot, columnVisibility: nil, content: nil, detail: detail())
  }

  /// Creates a 2-column split view with a route-driven sidebar, a custom detail column, and column visibility control.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type shared by both columns and split-level presentations.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///   - detail: A view builder for the detail column. Typically wraps a `RoutingView`.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar, columnVisibility: $visibility) {
  ///   RoutingView(destination: AppRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    sidebarRoot: Destination.R,
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, sidebarRoot: sidebarRoot, columnVisibility: columnVisibility, content: nil, detail: detail())
  }
}

// MARK: - 2-column (auto detail)

extension RoutingSplitView where Content == EmptyView, Detail == RoutingView<Destination, EmptyView> {

  /// Creates a 2-column split view where both sidebar and detail columns are automatically wrapped in a `RoutingView`.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type shared by both columns and split-level presentations.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - root: The initial route displayed in the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar, root: .home)
  /// ```
  public init(
    destination: Destination.Type,
    sidebarRoot: Destination.R,
    root: Destination.R
  ) {
    self.init(
      destination: destination,
      sidebarRoot: sidebarRoot,
      columnVisibility: nil,
      content: nil,
      detail: RoutingView(destination: destination, root: root)
    )
  }

  /// Creates a 2-column split view with auto-managed sidebar and detail columns, and column visibility control.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type shared by both columns and split-level presentations.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - root: The initial route displayed in the detail column.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar, root: .home, columnVisibility: $visibility)
  /// ```
  public init(
    destination: Destination.Type,
    sidebarRoot: Destination.R,
    root: Destination.R,
    columnVisibility: Binding<NavigationSplitViewVisibility>
  ) {
    self.init(
      destination: destination,
      sidebarRoot: sidebarRoot,
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
  ///   - destination: The `RouteDestination` type shared by both columns and split-level presentations.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - content: A view builder for the content (middle) column.
  ///   - detail: A view builder for the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar) {
  ///   ContentView()
  /// } detail: {
  ///   RoutingView(destination: AppRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    sidebarRoot: Destination.R,
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, sidebarRoot: sidebarRoot, columnVisibility: nil, content: content(), detail: detail())
  }

  /// Creates a 3-column split view with a route-driven sidebar, column visibility control, a content column, and a detail column.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type shared by both columns and split-level presentations.
  ///   - sidebarRoot: The initial route displayed in the sidebar column.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///   - content: A view builder for the content (middle) column.
  ///   - detail: A view builder for the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar, columnVisibility: $visibility) {
  ///   ContentView()
  /// } detail: {
  ///   RoutingView(destination: AppRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    sidebarRoot: Destination.R,
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, sidebarRoot: sidebarRoot, columnVisibility: columnVisibility, content: content(), detail: detail())
  }
}
