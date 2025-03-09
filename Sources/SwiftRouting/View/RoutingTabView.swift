//
//  RoutingTabBar.swift
//  swift-routing
//
//  Created by Kevin Budain on 06/03/2025.
//

import Observation
import SwiftUI

@MainActor
public struct RoutingTabView<Tab: TabRoute, Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var parent
  @Binding private var tab: Tab
  private let destination: Destination.Type
  private let content: (Destination.Type) -> Content

  public init(
    tab: Binding<Tab>,
    destination: Destination.Type,
    @ViewBuilder content: @escaping (Destination.Type) -> Content
  ) {
    self._tab = tab
    self.destination = destination
    self.content = content
  }

  public var body: some View {
    Wrapped(
      tabRouter: TabRouter(tab: _tab.wrappedValue, parent: parent),
      tab: $tab,
      destination: destination,
      content: content
    )
  }

  private struct Wrapped: View {

    @StateObject var tabRouter: TabRouter
    @Binding var tab: Tab
    let destination: Destination.Type
    let content: (Destination.Type) -> Content

    public var body: some View {
      TabView(selection: .tabToRoot(for: $tab, in: tabRouter)) {
        content(destination)
        // TODO: Try to had RoutingNavigationStack for each child
//        _VariadicView.Tree(TabViewContainer(currentTab: tab, destination: destination)) {
//          content(destination)
//        }
      }
      .environment(\.tabRouter, tabRouter)
      .onChange(of: tabRouter.tab) {
        if let tab = tabRouter.tab.wrapped as? Tab {
          self.tab = tab
        }
      }
    }
  }
}

struct TabViewContainer<Tab: TabRoute, Destination: RouteDestination>: _VariadicView_MultiViewRoot {

  let currentTab: Tab
  let destination: Destination.Type

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    ForEach(children) { child in
      if let tab = child.tab(as: Tab.self) {
        RoutingNavigationStack(tab: tab, destination: destination) { child }
      }
    }
  }
}


extension View {
  public func tab(_ tab: some TabRoute) -> some View {
    _trait(TabTraitKey.self, AnyHashable(tab))
  }
}

// https://stackoverflow.com/questions/78282952/how-swiftuis-tabview-identify-each-item-internally
private struct TabTraitKey: @preconcurrency _ViewTraitKey {
  @MainActor static var defaultValue: AnyHashable?
}

extension _VariadicView_Children.Element {
  var tab: AnyHashable? {
    self[TabTraitKey.self]
  }

  func tab<T: TabRoute>(as: T.Type) -> T? {
    tab as? T
  }
}
