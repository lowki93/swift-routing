//
//  SplitViewDeeplinkHandler.swift
//  SwiftRoutingDemo
//

import SwiftRouting

// Paradigm-level handler, same shape as NavigationStackDeeplinkHandler/TabViewDeeplinkHandler/
// TabRouterDeeplinkHandler: delegates to the per-feature handler. SplitViewDeeplinkID only has
// one case today, so this fixes itself to the 3-column shape (PlayerSplitDeeplinkHandler) --
// the 2-column shape (PlayerListDeeplinkHandler) can't be expressed by a single
// SplitDeeplinkHandler conformance since its ContentData/DetailData differ, so
// PendingSplitDeeplinkConsumer picks between the two directly instead of going through this type.
struct SplitViewDeeplinkHandler: SplitDeeplinkHandler {
  typealias R = SplitViewDeeplinkID
  typealias ContentData = PlayerType
  typealias DetailData = Player
  typealias D = AppRoute

  private let playerHandler = PlayerSplitDeeplinkHandler()

  func deeplink(from route: SplitViewDeeplinkID) async throws -> SplitDeeplink<PlayerType, Player, AppRoute>? {
    switch route {
    case let .players(target):
      try await playerHandler.deeplink(from: target)
    }
  }
}
