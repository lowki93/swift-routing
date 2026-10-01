//
//  PlayerSplitDeeplinkHandler.swift
//  SwiftRoutingDemo
//

import SwiftRouting

// 3-column layout shape: content = PlayerType, detail = Player. Used when SplitScreen's
// RoutingSplitView is in 3-column mode -- see PlayerListDeeplinkHandler for the 2-column
// shape, and PendingSplitDeeplinkConsumer for how the two are chosen between at runtime.
struct PlayerSplitDeeplinkHandler: SplitDeeplinkHandler {
  typealias R = PlayersDeeplinkID
  typealias ContentData = PlayerType
  typealias DetailData = Player
  typealias D = AppRoute

  func deeplink(from route: PlayersDeeplinkID) async throws -> SplitDeeplink<PlayerType, Player, AppRoute>? {
    switch route {
    case let .list(type):
      SplitDeeplink(content: type)
    case let .detail(type, name):
      Player.players.for(type: type)
        .first(where: { $0.name == name })
        .map { player in SplitDeeplink(content: type, detail: player) }
    }
  }
}
