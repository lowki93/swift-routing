//
//  SidebarView.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftRouting
import SwiftUI

struct SidebarScreen: View {

  @Environment(\.splitRouter2) private var splitRouter
  private let array: [PlayerType] = [.footballer, .basketballPlayer]

  var body: some View {
    List(array, selection: splitRouter?.contentBinding(as: PlayerType.self) ?? .constant(nil)) { item in
      NavigationLink(item.rawValue.capitalized, value: item)
    }
    .onFirstAppear {
      splitRouter?.select(content: array.first)
    }
    .navigationTitle("Sidebar")
  }
}
