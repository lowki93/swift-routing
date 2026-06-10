//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

  var body: some View {
    RoutingSplitView(
      columnVisibility: .detailOnly,
      preferredCompactColumn: $preferredCompactColumn,
      destination: AppRoute.self,
      sidebarRoot: .sidebar
    )
    .navigationSplitViewStyle(.balanced)
  }
}
