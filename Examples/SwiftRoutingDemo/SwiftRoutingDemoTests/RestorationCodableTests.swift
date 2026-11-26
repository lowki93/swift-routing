//
//  RestorationCodableTests.swift
//  SwiftRoutingDemoTests
//

import Foundation
import Testing

@testable import SwiftRoutingDemo

// Navigation state restoration persists routes and selections as JSON, so every demo type
// that ends up in a saved path must survive an encode -> decode roundtrip unchanged.
private func roundtrip<T: Codable>(_ value: T) throws -> T {
  let data = try JSONEncoder().encode(value)
  return try JSONDecoder().decode(T.self, from: data)
}

struct RestorationCodableTests {
  struct AppRouteRoundtrip {
    @Test(arguments: [
      AppRoute.home(name: "Kevin"),
      .notifications(.list),
      .notifications(.detail(id: 42)),
      .profile,
      .user(name: "Ben"),
      .search,
      .settings,
      .about,
      .sidebar,
      .players(.list(.footballer)),
      .players(.list(.basketballPlayer)),
      .players(.detail(.stable(7))),
      .form(.flow),
      .form(.entry),
    ])
    func givenAppRoute_whenRoundtripped_thenEqualsOriginal(expected: AppRoute) throws {
      #expect(try roundtrip(expected) == expected)
    }
  }

  struct ChildRouteRoundtrip {
    @Test(arguments: [PlayersRoute.list(.footballer), .list(.basketballPlayer), .detail(.stable(12))])
    func givenPlayersRoute_whenRoundtripped_thenEqualsOriginal(expected: PlayersRoute) throws {
      #expect(try roundtrip(expected) == expected)
    }

    @Test(arguments: [FormRoute.flow, .entry])
    func givenFormRoute_whenRoundtripped_thenEqualsOriginal(expected: FormRoute) throws {
      #expect(try roundtrip(expected) == expected)
    }

    @Test(arguments: [NotificationsRoute.list, .detail(id: 3)])
    func givenNotificationsRoute_whenRoundtripped_thenEqualsOriginal(expected: NotificationsRoute) throws {
      #expect(try roundtrip(expected) == expected)
    }

    @Test
    func givenFailedRoute_whenRoundtripped_thenEqualsOriginal() throws {
      #expect(try roundtrip(FailedRoute.failed) == .failed)
    }
  }

  struct TabRoundtrip {
    @Test(arguments: [HomeTab.home, .notifications, .profile])
    func givenHomeTab_whenRoundtripped_thenEqualsOriginal(expected: HomeTab) throws {
      #expect(try roundtrip(expected) == expected)
    }
  }

  struct SelectionRoundtrip {
    @Test(arguments: [PlayerType.footballer, .basketballPlayer])
    func givenPlayerType_whenRoundtripped_thenEqualsOriginal(expected: PlayerType) throws {
      #expect(try roundtrip(expected) == expected)
    }

    @Test(arguments: Player.players.map { $0.id })
    func givenPlayerID_whenRoundtripped_thenEqualsOriginal(expected: Player.ID) throws {
      #expect(try roundtrip(expected) == expected)
    }

    @Test(arguments: Player.players)
    func givenPlayer_whenRoundtripped_thenEqualsOriginal(expected: Player) throws {
      #expect(try roundtrip(expected) == expected)
    }
  }

  struct StablePlayerIDs {
    @Test
    func givenStaticPlayers_whenAccessedTwice_thenSameIDs() {
      #expect(Player.players.map(\.id) == Player.players.map { $0.id })
    }

    @Test
    func givenStaticPlayers_whenListed_thenIDsAreUniqueAndFixed() {
      let expected = (1...20).map { UUID.stable(UInt8($0)) }
      #expect(Player.players.map(\.id) == expected)
      #expect(Set(Player.players.map { $0.id }).count == Player.players.count)
    }

    @Test
    func givenStableID_whenEncoded_thenFixedUUIDString() throws {
      let data = try JSONEncoder().encode(Player.players[0].id)
      #expect(String(decoding: data, as: UTF8.self) == "\"00000000-0000-0000-0000-000000000001\"")
    }

    @Test
    func givenSavedPlayerID_whenResolved_thenReturnsSamePlayer() throws {
      let saved = try roundtrip(Player.players[10].id)
      #expect(Player.player(id: saved) == Player.players[10])
    }
  }
}
