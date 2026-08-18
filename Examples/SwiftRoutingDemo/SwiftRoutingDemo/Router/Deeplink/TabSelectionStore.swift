//
//  TabSelectionStore.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 18/08/2026.
//

import Observation

// TabScreen's plain TabView (no TabRouter) drives tab selection from a private @State,
// which a deeplink has no way to influence -- this store is lifted to the App level so
// ChoiceScreen's `.onOpenURL` can select the target tab directly.
@Observable @MainActor
final class TabSelectionStore {
  var tab: HomeTab = .home
}
