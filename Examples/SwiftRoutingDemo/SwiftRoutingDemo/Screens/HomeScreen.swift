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
  @State var model: HomeScreenModel

  var body: some View {
    VStack {
      Button("Search") { router.present(AppRoute.search, withStack: false) }
      Button("User: lowki") { router.push(AppRoute.user(name: "Lowki")) }
      NavigationLink(route: AppRoute.user(name: "Alexia")) {
        Text("User: alexia")
      }
      Button("Failed push") { router.push(FailedRoute.failed) }
    }
    .navigationTitle("Hello " + model.name)
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Settings") {
          router.present(AppRoute.settings)
        }
      }
    }
    .routerContext(String.self) {
      print("=== String", $0)
    }
    .routerContext(Success.self) {
      print("=== Success", $0)
    }
    .routerPresent {
      print("=== HomeScreen : ", $0, $1)
    }
  }
}

@Observable
final class HomeScreenModel {
  private(set) var name: String

  init(name: String) {
    self.name = name
  }
}
