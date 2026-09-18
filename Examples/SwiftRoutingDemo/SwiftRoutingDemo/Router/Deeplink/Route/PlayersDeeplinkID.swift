//
//  PlayersDeeplinkID.swift
//  SwiftRoutingDemo
//

import URLRouting

enum PlayersDeeplinkID: Hashable {
  case list(PlayerType)
  case detail(type: PlayerType, name: String)
}

let playersDeeplinkRouter = OneOf {
  Route(PlayersDeeplinkID.list) {
    Path {
      "players"
      Rest().map(.string.representing(PlayerType.self))
    }
  }
  Route(PlayersDeeplinkID.detail) {
    Path {
      "players"
      Rest().map(.string.representing(PlayerType.self))
      Rest().map(.string)
    }
  }
}
