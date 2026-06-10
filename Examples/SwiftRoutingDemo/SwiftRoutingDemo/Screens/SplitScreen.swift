//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  var body: some View {
    RoutingSplitView2(destination: AppRoute.self, sidebarRoot: .sidebar) { (type: PlayerType) in
      AppRoute.players(type)
    } detail: { (player: Player) in
      AppRoute.player(player)
    }
  }
}
