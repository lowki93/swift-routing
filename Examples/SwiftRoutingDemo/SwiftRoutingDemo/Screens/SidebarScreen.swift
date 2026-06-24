//
//  SidebarView.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftRouting
import SwiftUI

struct SidebarScreen: View {

  @Environment(\.router) private var router
  @Environment(\.isSplitThreeColumn) private var isThreeColumn
  @Environment(\.columnVisibility) private var columnVisibility
  @Environment(\.preferredCompactColumn) private var preferredCompactColumn
  private let array: [PlayerType] = [.footballer, .basketballPlayer]

  private var selection: Binding<PlayerType?> {
    router.hasContentColumn
      ? router.contentBinding(as: PlayerType.self)
      : router.detailBinding(as: PlayerType.self)
  }

  var body: some View {
    List(array, selection: selection) { item in
      NavigationLink(item.rawValue.capitalized, value: item)
    }
    .onFirstAppear {
      if router.hasContentColumn {
        router.select(content: array.first)
      } else {
        router.select(detail: array.first)
      }
    }
    .navigationTitle("Sidebar")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Menu("Configuration") {
          Group {
            columnNumberPicker
            columnVisibilityPicker
            preferredCompactColumnPicker
          }
          .pickerStyle(.menu)
        }
      }
    }
  }

  private var columnNumberPicker: some View {
    Picker("Columns", selection: isThreeColumn) {
      Text("2 columns").tag(false)
      Text("3 columns").tag(true)
    }
  }

  private var columnVisibilityPicker: some View {
    Picker("ColumnVisibility", selection: columnVisibility) {
      ForEach(ColumnVisibility.allCases) { columnVisibility in
        Text(columnVisibility.rawValue.capitalized).tag(columnVisibility)
      }
    }
  }

  private var preferredCompactColumnPicker: some View {
    Picker("PreferredCompactColumn", selection: preferredCompactColumn) {
      Text("Sidebar").tag(NavigationSplitViewColumn.sidebar)
      Text("Content").tag(NavigationSplitViewColumn.content)
      Text("Detail").tag(NavigationSplitViewColumn.detail)
    }
  }
}
