//
//  UserScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftRouting
import SwiftUI

struct UserScreen: View {

  @Environment(\.dismiss) private var dismiss
  @State var model: UserScreenModel
  let viewModel: UserViewModel

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello \(model.name)")
      Button("User: Ben") {
        viewModel.pushBen()
      }
      Button("Back") {
        viewModel.back()
      }
      Button("Back (SwiftUI dismiss)") {
        // Pops the same way a swipe-back would -- logs .action(.back(count: 1)) via
        // path's didSet, same as viewModel.back() above. Stays a View-level concern,
        // unlike the router-driven actions above which go through the ViewModel.
        dismiss()
      }
      Button("Pop to root") {
        viewModel.popToRoot()
      }
    }
    .padding()
  }
}

@Observable
final class UserScreenModel {
  private(set) var name: String

  init(name: String) {
    self.name = name
  }
}

// Demonstrates injecting `any RouterModel` into a ViewModel (Testing.md "Strategy 2"),
// so navigation can be unit-tested with RouterSpy instead of exercising real UI.
// Built in AppRoute's RouteDestination (Route.swift), the only place `@Environment(\.router)`
// needs resolving for this route.
@MainActor
final class UserViewModel {
  private let name: String
  private let router: any RouterModel

  init(name: String, router: any RouterModel) {
    self.name = name
    self.router = router
  }

  func pushBen() {
    router.push(AppRoute.user(name: "Ben"))
  }

  func back() {
    router.back()
  }

  func popToRoot() {
    router.popToRoot()
  }
}
