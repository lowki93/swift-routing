//
//  HomeScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftRouting
import SwiftUI

struct HomeScreen: View {

  @Environment(\.router) private var router

  var body: some View {
    VStack {
      Button("User") {
        router.push(AppRoute.user(name: "Lowki"))
      }
    }
    .navigationTitle("Home")
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Settings") {
          router.present(AppRoute.settings)
        }
      }
    }
  }
}
