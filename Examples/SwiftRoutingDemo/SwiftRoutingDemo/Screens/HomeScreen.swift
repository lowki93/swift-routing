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
      Button("User: lowki") {
        router.push(AppRoute.user(name: "Lowki"))
      }
      NavigationLink(value: AppRoute.user(name: "Alexia")) {
        Text("User: alexia")
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
