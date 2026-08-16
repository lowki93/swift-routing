//
//  PlayerSplitDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 16/08/2026.
//

import SwiftRouting

enum PlayerDeeplinkID: Hashable {
  case player(Player)
}

struct PlayerSplitDeeplinkHandler: SplitDeeplinkHandler {
  typealias R = PlayerDeeplinkID
  typealias ContentData = PlayerType
  typealias DetailData = Player
  typealias D = AppRoute

  func deeplink(from route: PlayerDeeplinkID) async throws -> SplitDeeplink<PlayerType, Player, AppRoute>? {
    switch route {
    case let .player(player):
      SplitDeeplink(content: player.type, detail: player)
    }
  }
}
