//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  var body: some View {
    RoutingSplitView(destination: AppRoute.self, sidebarRoot: .sidebar, root: .home(name: "John"))
  }
}

// MARK: - Views

struct SidebarView: View {

  var body: some View {
    List {
      NavigationLink(route: AppRoute.players(.footballer)) { Text("Footballers") }
      NavigationLink(route: AppRoute.players(.basketballPlayer)) { Text("Basketball Players") }
    }
    .navigationTitle("Sidebar")
    .onAppear {
      print("========")
    }
  }
}

struct PlayersView: View {

  let type: PlayerType

  var body: some View {
    List {
      Text("====")
      Text("---")
    }
  }
}
