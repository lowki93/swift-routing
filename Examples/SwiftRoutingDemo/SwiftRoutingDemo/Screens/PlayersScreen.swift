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
    Group {
      if splitRouter?.hasContentColumn == true {
        List(Player.players.for(type: type), selection: splitRouter?.detailBinding(as: Player.self) ?? .constant(nil)) { item in
          NavigationLink(item.name, value: item)
        }
        .onFirstAppear {
          splitRouter?.select(detail: Player.players.for(type: type).first)
        }
      } else {
        List(Player.players.for(type: type)) { item in
          NavigationLink(item.name, route: AppRoute.player(item))
        }
      }
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
