//
//  PlayersScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftRouting
import SwiftUI

struct PlayersScreen: View {

  @Environment(\.splitRouter) private var splitRouter
  @State private var selection: Player?
  let type: PlayerType

  var body: some View {
    List(Player.players.for(type: type), selection: $selection) { item in
      if splitRouter?.columVisibility == .doubleColumn {
        NavigationLink(item.name, value: item)
          .foregroundStyle(.blue)
      } else {
//        NavigationLink(item.name, value: item)
        NavigationLink(item.name, route: AppRoute.player(item))
          .foregroundStyle(.red)
      }
    }
    .splitRouterRouteToDetails(selection.flatMap { AppRoute.player($0) })
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
