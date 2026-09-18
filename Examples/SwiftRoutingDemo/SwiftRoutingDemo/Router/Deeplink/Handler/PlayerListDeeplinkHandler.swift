//
//  PlayerListDeeplinkHandler.swift
//  SwiftRoutingDemo
//

import SwiftRouting

// 2-column layout shape: SplitScreen's 2-column RoutingSplitView has no content column
// (ContentData == Never) and routes the sidebar's type selection straight to the players list
// in the detail column's own NavigationStack (DetailData == PlayerType). A specific player is
// reached by pushing .players(.detail(player)) within that stack via the optional deeplink,
// not by a router-level detail selection -- there's no "selected player" concept in 2-column
// mode, only a "selected type" and whatever's been pushed on top of its list.
struct PlayerListDeeplinkHandler: SplitDeeplinkHandler {
  typealias R = PlayersDeeplinkID
  typealias ContentData = Never
  typealias DetailData = PlayerType
  typealias D = AppRoute

  func deeplink(from route: PlayersDeeplinkID) async throws -> SplitDeeplink<Never, PlayerType, AppRoute>? {
    switch route {
    case let .list(type):
      SplitDeeplink(detail: type)
    case let .detail(type, name):
      Player.players.for(type: type)
        .first(where: { $0.name == name })
        .map { player in SplitDeeplink(detail: type, deeplink: .push(AppRoute.players(.detail(player)))) }
    }
  }
}
