//
//  PlayerScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftUI

struct PlayerScreen: View {

  @Environment(\.splitRouter) private var splitRouter
  let player: Player

  var body: some View {
    ScrollView {
      VStack {
        Text(player.name)
        Text(player.type.rawValue)
      }
    }
  }
}
