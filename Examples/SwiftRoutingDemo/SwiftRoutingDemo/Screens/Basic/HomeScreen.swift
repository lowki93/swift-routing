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
      Button("About (cover)") { router.cover(AppRoute.about) }
      Button("User: lowki") { router.push(AppRoute.user(name: "Lowki")) }
      NavigationLink(route: AppRoute.user(name: "Alexia")) {
        Text("User: alexia")
      }
      Button("Failed push") { router.push(FailedRoute.failed) }
      Button("Form flow (push + sheet)") { router.push(AppRoute.formFlow) }
      // No FormResult observer registered here, so canTerminate(FormResult.self) is
      // false inside FormScreen and its Save button stays disabled.
      Button("Form (no listener)") { router.present(AppRoute.form) }
    }
    .navigationTitle("Hello " + model.name)
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Settings") {
          router.present(AppRoute.settings)
        }
      }
    }
    .routerPresent {
      print("RouterPresent HomeScreen : ", $0, $1)
    }
    .onTabReselected(HomeTab.home) {
      print("=== HomeTab.home")
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
