//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

extension EnvironmentValues {
  @Entry var isSplitThreeColumn: Binding<Bool> = .constant(false)
}

struct SplitScreen: View {

  @State private var isThreeColumn = false

  var body: some View {
    Group {
      if isThreeColumn {
        RoutingSplitView2(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
          AppRoute.players(type)
        } detail: { (player: Player) in
          AppRoute.player(player)
        }
      } else {
        RoutingSplitView2(destination: AppRoute.self, sidebar: .sidebar) { (type: PlayerType) in
          AppRoute.players(type)
        }
      }
    }
    .environment(\.isSplitThreeColumn, $isThreeColumn)
  }
}
