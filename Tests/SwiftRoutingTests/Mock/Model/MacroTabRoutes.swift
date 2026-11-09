import SwiftRoutingMacros

/// Mirrors the demo app's `HomeTab` (`Examples/SwiftRoutingDemo/SwiftRoutingDemo/Router/TabRoute.swift`).
/// No explicit `: TabRoute`: the macro's extension adds the conformance.
@TabRoutable
enum MacroHomeTab {
  @HideTabBarOnPush
  case home
  case notifications
  case profile
}

/// Mirrors `TestTabRoute`.
@TabRoutable
enum MacroTestTabRoute {
  case home
  case settings
}

/// Mirrors `OtherTestTabRoute`, with an explicit `: TabRoute` (the macro adds no extension).
@TabRoutable
enum MacroOtherTestTabRoute: TabRoute {
  case main
}

/// Mirrors `FixtureTab` from `SwiftRoutingTestSupportTests`, which has no macros dependency.
@TabRoutable
enum MacroFixtureTab {
  case home
  case profile
}

/// Every case is marked, so `hideTabBarOnPush` is a constant `true`.
@TabRoutable(nameStyle: .capitalized)
enum MacroImmersiveTab {
  @HideTabBarOnPush
  case player, reader
}
