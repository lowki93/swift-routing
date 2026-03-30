//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  var body: some View {
    RoutingSplitView(destination: AppRoute.self) {
      RoutingView(destination: SidebarRoute.self, root: .list)
    } detail: {
      RoutingView(destination: AppRoute.self, root: .home(name: "John"))
    }
  }
}

// MARK: - SidebarRoute

enum PlayerType: String {
  case footballer
  case basketballPlayer
}

enum SidebarRoute: Route {
  case list
  case players(PlayerType)

  var name: String {
    switch self {
    case .list: "list"
    case .players(let type): type.rawValue
    }
  }
}

extension SidebarRoute: RouteDestination {
  static func view(for route: SidebarRoute) -> some View {
    switch route {
    case .list: SidebarView()
    case .players(let type): PlayersView(type: type)
    }
  }
}

// MARK: - Views

struct SidebarView: View {

  var body: some View {
    List {
      NavigationLink(route: SidebarRoute.players(.footballer)) { Text("Footballers") }
      NavigationLink(route: SidebarRoute.players(.basketballPlayer)) { Text("Basketball Players") }
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
