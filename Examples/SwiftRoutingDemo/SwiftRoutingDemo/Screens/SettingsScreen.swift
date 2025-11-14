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
  @State var model: SettingsScreenModel

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
          router.terminate(Success(value: 4))
        }
      }
    }
    .routerContext(Int.self) { [model] context in
      Task {
        await model.update(int: context)
      }
    }
  }
}

@Observable @MainActor
final class SettingsScreenModel {

  init() {}

  func update(int: Int) async {
    print("=====")
  }
}
