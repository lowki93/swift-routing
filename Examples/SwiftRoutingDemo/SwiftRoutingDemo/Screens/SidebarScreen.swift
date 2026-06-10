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
  @Environment(\.isSplitThreeColumn) private var isThreeColumn
  @Environment(\.horizontalSizeClass) private var sizeClass
  private let array: [PlayerType] = [.footballer, .basketballPlayer]

  private var selection: Binding<PlayerType?> {
    guard let splitRouter else { return .constant(nil) }
    return splitRouter.hasContentColumn
      ? splitRouter.contentBinding(as: PlayerType.self)
      : splitRouter.detailBinding(as: PlayerType.self)
  }

  var body: some View {
    List(array, selection: selection) { item in
      NavigationLink(item.rawValue.capitalized, value: item)
    }
    .onFirstAppear {
      // On compact (iPhone), NavigationSplitView collapses — programmatic selection
      // highlights the cell but doesn't trigger the push. Skip auto-select; user taps to navigate.
      guard sizeClass != .compact, let splitRouter else { return }
      if splitRouter.hasContentColumn {
        splitRouter.select(content: array.first)
      } else {
        splitRouter.select(detail: array.first)
      }
    }
    .navigationTitle("Sidebar")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Picker("Columns", selection: isThreeColumn) {
          Text("2 columns").tag(false)
          Text("3 columns").tag(true)
        }
        .pickerStyle(.segmented)
      }
    }
  }
}
