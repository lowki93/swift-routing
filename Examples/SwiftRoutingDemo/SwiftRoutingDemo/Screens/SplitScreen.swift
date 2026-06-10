//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

private struct SplitColumnModeKey: EnvironmentKey {
  static var defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
  var isSplitThreeColumn: Binding<Bool> {
    get { self[SplitColumnModeKey.self] }
    set { self[SplitColumnModeKey.self] = newValue }
  }
}

struct SplitScreen: View {

  @State private var isThreeColumn = false

  var body: some View {
    Group {
      if isThreeColumn {
        RoutingSplitView2(destination: AppRoute.self, sidebarRoot: .sidebar) { (type: PlayerType) in
          AppRoute.players(type)
        } detail: { (player: Player) in
          AppRoute.player(player)
        }
      } else {
        RoutingSplitView2(destination: AppRoute.self, sidebarRoot: .sidebar) { (type: PlayerType) in
          AppRoute.players(type)
        }
      }
    }
    .environment(\.isSplitThreeColumn, $isThreeColumn)
  }
}
