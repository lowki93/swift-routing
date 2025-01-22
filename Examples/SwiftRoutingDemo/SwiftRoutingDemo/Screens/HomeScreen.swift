//
//  HomeScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftRouting
import SwiftUI

struct HomeScreen: View {

  @State var router = AppRouter()

  var body: some View {
    NavigationStack(path: $router.path) {
      VStack {
        Button("User") {
          router.push(.user(name: "Lowki"))
        }
      }
      .navigationTitle("Home")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Settings") {
            router.present(.settings)
          }
        }
      }
      .navigationDestination(AppRoute.self)
    }
    .sheet(for: $router.sheet) { $0.view }
    .cover(for: $router.cover) { $0.view }
  }
}


public extension View {
  func sheet<Item>(
    for item: Binding<Item?>,
    @ViewBuilder destination: @escaping (Item) -> some View,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    sheet(
      isPresented: Binding(bindingOptional: item),
      onDismiss: onDismiss
    ) {
      if let modal = item.wrappedValue {
        destination(modal)
      } else {
        EmptyView()
      }
    }
  }
}

public extension View {
  func cover<Item>(
    for item: Binding<Item?>,
    @ViewBuilder destination: @escaping (Item) -> some View,
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    fullScreenCover(
      isPresented: Binding(bindingOptional: item),
      onDismiss: onDismiss
    ) {
      if let modal = item.wrappedValue {
        destination(modal)
      } else {
        EmptyView()
      }
    }
  }
}

public extension Binding where Value == Bool {
  init(bindingOptional: Binding<(some Any)?>) {
    self.init(
      get: {
        bindingOptional.wrappedValue != nil
      },
      set: { newValue in
        guard newValue == false else { return }

        /// We only handle `false` booleans to set our optional to `nil`
        /// as we can't handle `true` for restoring the previous value.
        bindingOptional.wrappedValue = nil
      }
    )
  }
}
