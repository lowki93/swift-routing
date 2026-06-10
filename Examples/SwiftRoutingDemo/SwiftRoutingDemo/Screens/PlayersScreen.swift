//
//  PlayersScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftRouting
import SwiftUI

struct PlayersScreen: View {

  @Environment(\.router) private var router
  @Environment(\.splitRouter) private var splitRouter
  @State private var selection: Player?
  let type: PlayerType

  var body: some View {
    Group {
      switch splitRouter?.columVisibility {
      case .detailOnly: detailsOnlyList
      case .doubleColumn: doubleColumnList
      case nil: EmptyView()
      }
    }
    .onAppear {
      selection = nil
    }
    .navigationTitle("Players")
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button("Settings") {
          splitRouter?.present(AppRoute.settings)
        }
      }
    }
  }

  var doubleColumnList: some View {
    List(Player.players.for(type: type), selection: $selection) { item in
      NavigationLink(item.name, value: item)
        .foregroundStyle(.blue)
    }
    .splitRouterRouteToDetails(selection.flatMap { AppRoute.player($0) })
  }

  var detailsOnlyList: some View {
    List(Player.players.for(type: type), selection: $selection) { item in
      NavigationLink(item.name, value: item)
        .foregroundStyle(.red)
    }
    .splitRouterPush(selection.flatMap { AppRoute.player($0) })
  }
}
