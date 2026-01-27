//
//  UserScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI

struct UserScreen: View {

  @Environment(\.router) private var router
  @State var model: UserScreenModel

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello \(model.name)")
      Button("User: Ben") {
        router.push(AppRoute.user(name: "Ben"))
      }
//      if router.canTerminate {
        Button("Go back") {
          router.terminate(model.name)
        }
//      }
    }
    .padding()
    .routerContext(String.self) { context in
      print("=== ", context)
    }
  }
}

@Observable
final class UserScreenModel {
  private(set) var name: String

  init(name: String) {
    self.name = name
  }
}
