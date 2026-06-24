//
//  PlayersScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftRouting
import SwiftUI

struct PlayersScreen: View {

  @Environment(\.router) private var router
  @Environment(\.isSplitThreeColumn) private var isThreeColumn
  @Environment(\.columnVisibility) private var columnVisibility
  let type: PlayerType

  var body: some View {
    VStack(alignment: .leading) {
      Group {
        if router.hasContentColumn {
          List(Player.players.for(type: type), selection: router.detailBinding(as: Player.self)) { item in
            NavigationLink(item.name, value: item)
          }
          .onFirstAppear {
            router.select(detail: Player.players.for(type: type).first)
          }
        } else {
          List(Player.players.for(type: type)) { item in
            NavigationLink(item.name, route: AppRoute.player(item))
          }
        }
      }
    }
    .navigationTitle("Players")
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Settings") {
          router.present(AppRoute.settings)
        }
      }
    }
  }
}
