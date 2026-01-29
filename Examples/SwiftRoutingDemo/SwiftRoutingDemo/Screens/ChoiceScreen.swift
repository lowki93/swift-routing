//
//  ChoiceScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kévin Budain on 3/16/25.
//

import SwiftRouting
import SwiftUI

struct ChoiceScreen: View {
  @AppStorage("example") private var example: Example?

  var body: some View {
      switch example {
      case .none: choiceView
      case .navigationStack: RoutingView(destination: AppRoute.self, root: .home(name: "John"))
      case .tabView: TabScreen(type: .tabView)
      case .routingTabView: TabScreen(type: .routingTabView)
    }
  }

  private var choiceView: some View {
    VStack {
      Button("Navigation Stack") { example = .navigationStack }
      Button("TabView") { example = .tabView }
      Button("RoutingTabView") { example = .routingTabView }
    }
  }
}
