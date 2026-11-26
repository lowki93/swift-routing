//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  static let isThreeColumnKey = "SwiftRoutingDemo.split.isThreeColumn"
  static let columnVisibilityKey = "SwiftRoutingDemo.split.columnVisibility"

  // The layout is persisted per window: the 2-column and 3-column splits share the restoration
  // key `split(Sidebar)` but have different data types, so restoring the saved navigation into
  // the other layout would fail and fall back to the default state.
  @SceneStorage(Self.isThreeColumnKey) private var isThreeColumn = false
  @SceneStorage(Self.columnVisibilityKey) private var columnVisibility: ColumnVisibility = .all
  @State private var preferredCompactColumn: NavigationSplitViewColumn = .detail

  var body: some View {
    Group {
      if isThreeColumn {
        RoutingSplitView(
          columnVisibility: Binding(
            get: { NavigationSplitViewVisibility(from: columnVisibility) },
            set: { columnVisibility = $0.toColumnVisibility() }
          ),
          preferredCompactColumn: $preferredCompactColumn,
          destination: AppRoute.self,
          sidebar: .sidebar) { (type: PlayerType) in
            .players(.list(type))
          } detail: { (id: Player.ID) in
            .players(.detail(id))
          }
      } else {
        RoutingSplitView(
          preferredCompactColumn: $preferredCompactColumn,
          destination: AppRoute.self,
          sidebar: .sidebar
        ) { (type: PlayerType) in
          .players(.list(type))
        }
      }
    }
    .environment(\.isSplitThreeColumn, $isThreeColumn)
    .environment(\.columnVisibility, $columnVisibility)
    .environment(\.preferredCompactColumn, $preferredCompactColumn)
  }
}
