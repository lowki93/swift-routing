//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  @State private var isThreeColumn = false
  @State private var columnVisibility: ColumnVisibility = .all
  @State private var preferredCompactColumn: NavigationSplitViewColumn = .detail

  var body: some View {
    Group {
      if isThreeColumn {
        RoutingSplitView2(
          columnVisibility: Binding(
            get: { NavigationSplitViewVisibility(from: columnVisibility) },
            set: { columnVisibility = $0.toColumnVisibility() }
          ),
          preferredCompactColumn: $preferredCompactColumn,
          destination: AppRoute.self,
          sidebar: .sidebar) { (type: PlayerType) in
            .players(type)
          } detail: { (player: Player) in
            .player(player)
          }
      } else {
        RoutingSplitView2(
          preferredCompactColumn: $preferredCompactColumn,
          destination: AppRoute.self,
          sidebar: .sidebar
        ) { (type: PlayerType) in
          .players(type)
        }
      }
    }
    .environment(\.isSplitThreeColumn, $isThreeColumn)
    .environment(\.columnVisibility, $columnVisibility)
    .environment(\.preferredCompactColumn, $preferredCompactColumn)
  }
}
