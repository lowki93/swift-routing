//
//  UserScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI

struct UserScreen: View {

  @Environment(\.router) private var router
  let name: String

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello \(name)")
      Button("User: Ben") {
        router.push(AppRoute.user(name: "Ben"))
      }
//      if router.canTerminate {
        Button("Go back") {
          router.back(name)
        }
//      }
    }
    .padding()
  }
}
