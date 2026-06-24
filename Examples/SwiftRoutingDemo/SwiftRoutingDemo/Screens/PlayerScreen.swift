//
//  PlayerScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftUI

struct PlayerScreen: View {

  @Environment(\.router) private var router
  @Environment(\.splitRouter2) private var splitRouter
  @Environment(\.currentRouter) private var currentRouter

  let player: Player

  var body: some View {
    ScrollView {
      VStack {
        Text(player.name)
        Text(player.type.rawValue)
        Button("Search") { splitRouter?.present(AppRoute.search, withStack: false) }
      }
      .onAppear { print("Router: On Appear:", router, currentRouter) }
    }
  }
}
