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
/// Each column can embed a `RoutingView` to get its own independent navigation stack.
///
/// ## Examples
/// ```swift
/// // 2-column, manual detail
/// RoutingSplitView(destination: AppRoute.self) {
///   SidebarView()
/// } detail: {
///   RoutingView(destination: DetailRoute.self, root: .home)
/// }
///
/// // 2-column, detail managed automatically
/// RoutingSplitView(destination: DetailRoute.self, root: .home) {
///   SidebarView()
/// }
///
/// // 3-column
/// RoutingSplitView(destination: AppRoute.self) {
///   SidebarView()
/// } content: {
///   ContentView()
/// } detail: {
///   RoutingView(destination: DetailRoute.self, root: .home)
/// }
///
/// // With column visibility binding
/// RoutingSplitView(destination: AppRoute.self, columnVisibility: $visibility) {
///   SidebarView()
/// } detail: {
///   RoutingView(destination: DetailRoute.self, root: .home)
/// }
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
public struct RoutingSplitView<Destination: RouteDestination, Sidebar: View, Content: View, Detail: View>: View {

  @Environment(\.router) private var parent
  private let destination: Destination.Type
  private let columnVisibility: Binding<NavigationSplitViewVisibility>?
  private let sidebar: Sidebar
  private let content: Content?
  private let detail: Detail

  init(
    destination: Destination.Type,
    columnVisibility: Binding<NavigationSplitViewVisibility>?,
    sidebar: Sidebar,
    content: Content?,
    detail: Detail
  ) {
    self.destination = destination
    self.columnVisibility = columnVisibility
    self.sidebar = sidebar
    self.content = content
    self.detail = detail
  }

  public var body: some View {
    Wrapped(
      splitRouter: SplitRouter(parent: parent),
      destination: destination,
      columnVisibility: columnVisibility,
      sidebar: sidebar,
      content: content,
      detail: detail
    )
  }

  private struct Wrapped: View {

    @StateObject var splitRouter: SplitRouter
    let destination: Destination.Type
    let columnVisibility: Binding<NavigationSplitViewVisibility>?
    let sidebar: Sidebar
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

  /// Creates a 2-column split view with sidebar and detail columns.
  ///
  /// Use this when you want full control over the detail column content.
  /// A `SplitRouter` is injected into the environment for split-level sheet/cover presentations.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - sidebar: A view builder for the sidebar column.
  ///   - detail: A view builder for the detail column. Typically wraps a `RoutingView`.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self) {
  ///   SidebarView()
  /// } detail: {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    @ViewBuilder sidebar: () -> Sidebar,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, columnVisibility: nil, sidebar: sidebar(), content: nil, detail: detail())
  }

  /// Creates a 2-column split view with programmatic column visibility control.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///   - sidebar: A view builder for the sidebar column.
  ///   - detail: A view builder for the detail column. Typically wraps a `RoutingView`.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, columnVisibility: $visibility) {
  ///   SidebarView()
  /// } detail: {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    @ViewBuilder sidebar: () -> Sidebar,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, columnVisibility: columnVisibility, sidebar: sidebar(), content: nil, detail: detail())
  }
}

// MARK: - 2-column (auto detail)

extension RoutingSplitView where Content == EmptyView, Detail == RoutingView<Destination, EmptyView> {

  /// Creates a 2-column split view where the detail column is automatically wrapped in a `RoutingView`.
  ///
  /// This is a convenience initializer that creates a `RoutingView` for the detail column,
  /// using the same `Destination` type for both split-level presentations and detail navigation.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type, used for both the detail column and split-level presentations.
  ///   - root: The initial route displayed in the detail column.
  ///   - sidebar: A view builder for the sidebar column.
  ///
  /// ```swift
  /// RoutingSplitView(destination: DetailRoute.self, root: .home) {
  ///   SidebarView()
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    root: Destination.R,
    @ViewBuilder sidebar: () -> Sidebar
  ) {
    self.init(
      destination: destination,
      columnVisibility: nil,
      sidebar: sidebar(),
      content: nil,
      detail: RoutingView(destination: destination, root: root)
    )
  }

  /// Creates a 2-column split view with auto-managed detail and column visibility control.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type, used for both the detail column and split-level presentations.
  ///   - root: The initial route displayed in the detail column.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///   - sidebar: A view builder for the sidebar column.
  ///
  /// ```swift
  /// RoutingSplitView(destination: DetailRoute.self, root: .home, columnVisibility: $visibility) {
  ///   SidebarView()
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    root: Destination.R,
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    @ViewBuilder sidebar: () -> Sidebar
  ) {
    self.init(
      destination: destination,
      columnVisibility: columnVisibility,
      sidebar: sidebar(),
      content: nil,
      detail: RoutingView(destination: destination, root: root)
    )
  }
}

// MARK: - 3-column

extension RoutingSplitView {

  /// Creates a 3-column split view with sidebar, content, and detail columns.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - sidebar: A view builder for the sidebar column.
  ///   - content: A view builder for the content (middle) column.
  ///   - detail: A view builder for the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self) {
  ///   SidebarView()
  /// } content: {
  ///   ContentView()
  /// } detail: {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    @ViewBuilder sidebar: () -> Sidebar,
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, columnVisibility: nil, sidebar: sidebar(), content: content(), detail: detail())
  }

  /// Creates a 3-column split view with programmatic column visibility control.
  ///
  /// - Parameters:
  ///   - destination: The `RouteDestination` type used for split-level sheet and cover presentations.
  ///   - columnVisibility: A binding to control which columns are visible.
  ///   - sidebar: A view builder for the sidebar column.
  ///   - content: A view builder for the content (middle) column.
  ///   - detail: A view builder for the detail column.
  ///
  /// ```swift
  /// RoutingSplitView(destination: AppRoute.self, columnVisibility: $visibility) {
  ///   SidebarView()
  /// } content: {
  ///   ContentView()
  /// } detail: {
  ///   RoutingView(destination: DetailRoute.self, root: .home)
  /// }
  /// ```
  public init(
    destination: Destination.Type,
    columnVisibility: Binding<NavigationSplitViewVisibility>,
    @ViewBuilder sidebar: () -> Sidebar,
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
  ) {
    self.init(destination: destination, columnVisibility: columnVisibility, sidebar: sidebar(), content: content(), detail: detail())
  }
}
