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
          List(Player.players.for(type: type), selection: router.detailBinding(as: Player.ID.self)) { item in
            NavigationLink(item.name, value: item.id)
          }
          .onFirstAppear {
            let players = Player.players.for(type: type)
            // Keep an already-selected player of this type (e.g. deep-linked) instead of
            // stomping it with the first one -- only auto-select when there's nothing usable.
            // This also matters for navigation restoration: selecting a different player here
            // would count as a selection change and drop the restored nested state.
            if let selected = router.detailSelection as? Player.ID, players.contains(where: { $0.id == selected }) { return }
            router.select(detail: players.first?.id)
          }
        } else {
          List(Player.players.for(type: type)) { item in
            NavigationLink(item.name, route: AppRoute.players(.detail(item.id)))
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
