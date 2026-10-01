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
            let players = Player.players.for(type: type)
            // Keep an already-selected player of this type (e.g. deep-linked) instead of
            // stomping it with the first one -- only auto-select when there's nothing usable.
            if let selected = router.detailSelection as? Player, players.contains(selected) { return }
            router.select(detail: players.first)
          }
        } else {
          List(Player.players.for(type: type)) { item in
            NavigationLink(item.name, route: AppRoute.players(.detail(item)))
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
