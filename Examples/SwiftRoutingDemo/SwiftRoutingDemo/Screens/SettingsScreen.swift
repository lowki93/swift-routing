//
//  SettingsScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftRouting
import SwiftUI

struct SettingsScreen: View {
  @AppStorage("example") private var example: Example?
  @Environment(\.router) private var router

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
      Button("User") { router.push(AppRoute.user(name: "Lowki")) }
      Button("Back to choiseScreen") { example = nil }
    }
    .navigationTitle("Settings")
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Dismiss") {
          router.close(Success(value: 4))
        }
      }
    }
  }
}
