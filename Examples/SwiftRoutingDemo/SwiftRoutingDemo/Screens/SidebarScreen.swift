//
//  SidebarView.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftRouting
import SwiftUI

struct SidebarScreen: View {

  @State private var firstAppear = false
  @State private var selection: PlayerType?
  private let array: [PlayerType] = [.footballer, .basketballPlayer]

  var body: some View {
    List(array, selection: $selection) { item in
      NavigationLink(item.rawValue.capitalized, value: item)
    }
    .onFirstAppear {
      selection = array.first
    }
    .splitRouterRouteToContent(selection.flatMap { AppRoute.players($0) })
    .navigationTitle("Sidebar")
  }
}
