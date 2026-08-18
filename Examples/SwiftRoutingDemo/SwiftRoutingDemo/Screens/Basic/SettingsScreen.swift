//
//  SettingsScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftRouting
import SwiftUI

struct SettingsScreen: View {
  @Environment(\.router) private var router
  @State var model: SettingsScreenModel

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
      Button("User") { router.push(AppRoute.user(name: "Lowki")) }
      Button("Back to choice") { router.terminate(ChoiceReset()) }
    }
    .navigationTitle("Settings")
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Dismiss") {
          router.close()
        }
      }
    }
  }
}

@Observable @MainActor
final class SettingsScreenModel {

  init() {}
}
