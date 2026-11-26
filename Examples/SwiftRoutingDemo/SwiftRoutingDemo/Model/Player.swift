//
//  Player.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import Foundation

struct Player: Identifiable, Hashable, Codable {
  let id: UUID
  let name: String
  let type: PlayerType
}

extension UUID {
  // Fixed ids so a route or selection saved by navigation restoration still resolves after a
  // relaunch (`UUID()` would give every player a new id on each launch).
  static func stable(_ n: UInt8) -> UUID {
    UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, n))
  }
}

extension Player {
  /// Resolves a player from the stable id carried by routes and selections.
  static func player(id: Player.ID) -> Player? {
    players.first { $0.id == id }
  }

  static let players: [Player] = [
    Player(id: .stable(1), name: "Kylian Mbappé", type: .footballer),
    Player(id: .stable(2), name: "Erling Haaland", type: .footballer),
    Player(id: .stable(3), name: "Vinicius Jr.", type: .footballer),
    Player(id: .stable(4), name: "Jude Bellingham", type: .footballer),
    Player(id: .stable(5), name: "Rodri", type: .footballer),
    Player(id: .stable(6), name: "Lamine Yamal", type: .footballer),
    Player(id: .stable(7), name: "Phil Foden", type: .footballer),
    Player(id: .stable(8), name: "Florian Wirtz", type: .footballer),
    Player(id: .stable(9), name: "Bukayo Saka", type: .footballer),
    Player(id: .stable(10), name: "Harry Kane", type: .footballer),
    Player(id: .stable(11), name: "LeBron James", type: .basketballPlayer),
    Player(id: .stable(12), name: "Stephen Curry", type: .basketballPlayer),
    Player(id: .stable(13), name: "Giannis Antetokounmpo", type: .basketballPlayer),
    Player(id: .stable(14), name: "Nikola Jokić", type: .basketballPlayer),
    Player(id: .stable(15), name: "Luka Dončić", type: .basketballPlayer),
    Player(id: .stable(16), name: "Joel Embiid", type: .basketballPlayer),
    Player(id: .stable(17), name: "Kevin Durant", type: .basketballPlayer),
    Player(id: .stable(18), name: "Jayson Tatum", type: .basketballPlayer),
    Player(id: .stable(19), name: "Devin Booker", type: .basketballPlayer),
    Player(id: .stable(20), name: "Shai Gilgeous-Alexander", type: .basketballPlayer),
  ]
}

extension [Player] {
  func `for`(type: PlayerType) -> Self {
    filter { $0.type == type }
  }
}
