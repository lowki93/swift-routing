//
//  PlayerScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftUI

struct PlayerScreen: View {

  @Environment(\.router) private var router
  // The route carries a stable id, not the model: the player is looked up here, so a restored
  // route never shows stale data.
  let id: Player.ID

  var body: some View {
    ScrollView {
      VStack {
        if let player = Player.player(id: id) {
          Text(player.name)
          Text(player.type.rawValue)
        } else {
          Text("Unknown player")
        }
        Button("Search") { router.present(AppRoute.search, withStack: false) }
      }
    }
  }
}
