//
//  SplitScreen.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

struct SplitScreen: View {

  var body: some View {
    RoutingSplitView(columnVisibility: .detailOnly, destination: AppRoute.self, sidebarRoot: .sidebar)
  }
}
