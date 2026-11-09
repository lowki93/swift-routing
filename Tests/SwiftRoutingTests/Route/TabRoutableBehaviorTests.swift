import Testing
import SwiftRouting

struct TabRoutableBehaviorTests {

  /// Reproduces the demo app's `HomeTab` and the hand-written test tabs case by case, so a
  /// change to the macro's generated format breaks these tests instead of passing unnoticed.
  struct Parity {
    @Test(arguments: [
      (MacroHomeTab.home, "home"),
      (MacroHomeTab.notifications, "notifications"),
      (MacroHomeTab.profile, "profile"),
    ])
    func homeTabCases_name_matchDemoSwitch(tab: MacroHomeTab, expected: String) {
      #expect(tab.name == expected)
    }

    @Test(arguments: [
      (MacroHomeTab.home, true),
      (MacroHomeTab.notifications, false),
      (MacroHomeTab.profile, false),
    ])
    func homeTabCases_hideTabBarOnPush_matchDemoSwitch(tab: MacroHomeTab, expected: Bool) {
      #expect(tab.hideTabBarOnPush == expected)
    }

    @Test
    func testTabRouteCases_name_matchHandWritten() {
      #expect(MacroTestTabRoute.home.name == TestTabRoute.home.name)
      #expect(MacroTestTabRoute.settings.name == TestTabRoute.settings.name)
    }

    @Test
    func testTabRouteCases_hideTabBarOnPush_matchHandWritten() {
      #expect(MacroTestTabRoute.home.hideTabBarOnPush == TestTabRoute.home.hideTabBarOnPush)
      #expect(MacroTestTabRoute.settings.hideTabBarOnPush == TestTabRoute.settings.hideTabBarOnPush)
    }

    @Test
    func otherTestTabRouteCases_name_matchHandWritten() {
      #expect(MacroOtherTestTabRoute.main.name == OtherTestTabRoute.main.name)
    }

    @Test
    func otherTestTabRouteCases_hideTabBarOnPush_matchHandWritten() {
      #expect(MacroOtherTestTabRoute.main.hideTabBarOnPush == OtherTestTabRoute.main.hideTabBarOnPush)
    }

    /// `FixtureTab` lives in `SwiftRoutingTestSupportTests`, which can't see this target, so
    /// the expected values are the literals of its hand-written `name` switch.
    @Test(arguments: [
      (MacroFixtureTab.home, "home"),
      (MacroFixtureTab.profile, "profile"),
    ])
    func fixtureTabCases_name_matchFixtureSwitch(tab: MacroFixtureTab, expected: String) {
      #expect(tab.name == expected)
    }

    @Test(arguments: [MacroFixtureTab.home, MacroFixtureTab.profile])
    func fixtureTabCases_hideTabBarOnPush_return_false(tab: MacroFixtureTab) {
      #expect(!tab.hideTabBarOnPush)
    }
  }

  struct HideTabBarOnPushBehavior {
    @Test(arguments: [MacroImmersiveTab.player, MacroImmersiveTab.reader])
    func allElementsMarked_return_true(tab: MacroImmersiveTab) {
      #expect(tab.hideTabBarOnPush)
    }

    @Test
    func capitalizedStyle_tabName_return_capitalizedName() {
      #expect(MacroImmersiveTab.player.name == "Player")
      #expect(MacroImmersiveTab.reader.name == "Reader")
    }
  }

  struct SynthesizedConformance {
    @Test
    func synthesizedTab_conformsTo_hashableViaSet() {
      let set: Set<MacroHomeTab> = [.home, .profile, .profile]
      #expect(set.count == 2)
    }

    @Test
    func synthesizedTab_conformsTo_sendableAndHashable_viaGenericConstraint() {
      func accept<T: Hashable & Sendable>(_ value: T) -> T { value }
      #expect(accept(MacroHomeTab.home) == .home)
    }

    @Test
    func synthesizedTab_conformsTo_tabRouteViaGenericConstraint() {
      func accept<T: TabRoute>(_ value: T) -> T { value }
      #expect(accept(MacroHomeTab.home) == .home)
    }

    @Test
    func synthesizedTab_isUsableAs_anyTabRoute() {
      let tab: any TabRoute = MacroHomeTab.home
      #expect(tab.hideTabBarOnPush)
    }
  }
}
