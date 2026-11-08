import Testing
import SwiftRouting

struct RoutableBehaviorTests {

  /// Reproduces the real demo app's `AppRoute`/`PlayersRoute`/`FormRoute`/`NotificationsRoute`
  /// (`Examples/SwiftRoutingDemo/SwiftRoutingDemo/Router/Route.swift`) case by case, so a change
  /// to the macro's generated format breaks this test instead of passing unnoticed.
  struct Parity {
    @Test(arguments: [
      (MacroAppRoute.home(name: "Kevin"), "Home(Kevin)"),
      (MacroAppRoute.notifications(.detail(id: 1)), "Notifications.Notification(1)"),
      (MacroAppRoute.profile, "Profile"),
      (MacroAppRoute.user(name: "Ben"), "User(Ben)"),
      (MacroAppRoute.search, "Search"),
      (MacroAppRoute.settings, "Settings"),
      (MacroAppRoute.about, "About"),
      (MacroAppRoute.sidebar, "Sidebar"),
      (MacroAppRoute.players(.detail(MacroPlayer(name: "Mbappé", type: .footballer))), "Players.Player(Mbappé)"),
      (MacroAppRoute.form(.flow), "Form.FormFlow"),
    ])
    func appRouteCases_name_matchManualSwitch(route: MacroAppRoute, expected: String) {
      #expect(route.name == expected)
    }

    @Test(arguments: [
      (MacroPlayersRoute.list(.footballer), "Players(footballer)"),
      (MacroPlayersRoute.detail(MacroPlayer(name: "Mbappé", type: .footballer)), "Player(Mbappé)"),
    ])
    func playersRouteCases_name_matchManualSwitch(route: MacroPlayersRoute, expected: String) {
      #expect(route.name == expected)
    }

    @Test(arguments: [
      (MacroFormRoute.flow, "FormFlow"),
      (MacroFormRoute.entry, "Form"),
    ])
    func formRouteCases_name_matchManualSwitch(route: MacroFormRoute, expected: String) {
      #expect(route.name == expected)
    }

    @Test(arguments: [
      (MacroNotificationsRoute.list, "Notifications"),
      (MacroNotificationsRoute.detail(id: 7), "Notification(7)"),
    ])
    func notificationsRouteCases_name_matchManualSwitch(route: MacroNotificationsRoute, expected: String) {
      #expect(route.name == expected)
    }
  }

  struct NameStyleBehavior {
    @Test
    func capitalizedStyle_simpleCase_return_capitalizedName() {
      #expect(MacroAppRoute.search.name == "Search")
    }

    @Test
    func verbatimStyle_constantOverride_return_templateAsWritten() {
      #expect(MacroFormRoute.entry.name == "Form")
    }
  }

  struct Delegation {
    @Test
    func delegateCase_return_prefixDotChildName() {
      let route = MacroAppRoute.players(.list(.basketballPlayer))
      #expect(route.name == "Players.Players(basketballPlayer)")
    }
  }

  struct SynthesizedConformance {
    @Test
    func synthesizedRoute_conformsTo_hashableViaSet() {
      let set: Set<MacroSynthesizedRoute> = [.plain, .detail(id: 1), .detail(id: 1)]
      #expect(set.count == 2)
    }

    @Test
    func synthesizedRoute_conformsTo_sendableAndHashable_viaGenericConstraint() {
      func accept<T: Hashable & Sendable>(_ value: T) -> T { value }
      #expect(accept(MacroSynthesizedRoute.plain) == .plain)
    }

    @Test
    func synthesizedRoute_isUsableAs_anyRoute() {
      let route: any Route = MacroSynthesizedRoute.plain
      #expect(route.name == "plain")
    }
  }
}
