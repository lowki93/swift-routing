//
//  Player.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import Foundation

struct Player: Identifiable, Hashable {
  let id: UUID
  let name: String
  let type: PlayerType
}

extension Player {
  static let players: [Player] = [
    Player(id: UUID(), name: "Kylian Mbappé", type: .footballer),
    Player(id: UUID(), name: "Erling Haaland", type: .footballer),
    Player(id: UUID(), name: "Vinicius Jr.", type: .footballer),
    Player(id: UUID(), name: "Jude Bellingham", type: .footballer),
    Player(id: UUID(), name: "Rodri", type: .footballer),
    Player(id: UUID(), name: "Lamine Yamal", type: .footballer),
    Player(id: UUID(), name: "Phil Foden", type: .footballer),
    Player(id: UUID(), name: "Florian Wirtz", type: .footballer),
    Player(id: UUID(), name: "Bukayo Saka", type: .footballer),
    Player(id: UUID(), name: "Harry Kane", type: .footballer),
    Player(id: UUID(), name: "LeBron James", type: .basketballPlayer),
    Player(id: UUID(), name: "Stephen Curry", type: .basketballPlayer),
    Player(id: UUID(), name: "Giannis Antetokounmpo", type: .basketballPlayer),
    Player(id: UUID(), name: "Nikola Jokić", type: .basketballPlayer),
    Player(id: UUID(), name: "Luka Dončić", type: .basketballPlayer),
    Player(id: UUID(), name: "Joel Embiid", type: .basketballPlayer),
    Player(id: UUID(), name: "Kevin Durant", type: .basketballPlayer),
    Player(id: UUID(), name: "Jayson Tatum", type: .basketballPlayer),
    Player(id: UUID(), name: "Devin Booker", type: .basketballPlayer),
    Player(id: UUID(), name: "Shai Gilgeous-Alexander", type: .basketballPlayer),
  ]
}

extension [Player] {
  func `for`(type: PlayerType) -> Self {
    filter { $0.type == type }
  }
}
