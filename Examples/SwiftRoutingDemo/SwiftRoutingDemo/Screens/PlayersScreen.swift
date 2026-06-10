//
//  PlayersScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftRouting
import SwiftUI

struct PlayersScreen: View {

  @Environment(\.splitRouter2) private var splitRouter
  let type: PlayerType

  var body: some View {
    List(Player.players.for(type: type)) { item in
      NavigationLink(item.name, route: AppRoute.player(item))
    }
    .navigationTitle("Players")
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Settings") {
          splitRouter?.present(AppRoute.settings)
        }
      }
    }
  }
}
