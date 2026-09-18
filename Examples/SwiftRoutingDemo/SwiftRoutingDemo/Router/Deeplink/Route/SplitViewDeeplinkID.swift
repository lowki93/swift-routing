//
//  SplitViewDeeplinkID.swift
//  SwiftRoutingDemo
//

import URLRouting

enum SplitViewDeeplinkID: Hashable {
  case players(PlayersDeeplinkID)
}

let splitViewDeeplinkRouter = OneOf {
  Route(SplitViewDeeplinkID.players) {
    playersDeeplinkRouter
  }
}
