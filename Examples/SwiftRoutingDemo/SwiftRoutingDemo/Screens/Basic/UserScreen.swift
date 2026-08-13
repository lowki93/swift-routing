//
//  UserScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 22/01/2025.
//

import SwiftUI

struct UserScreen: View {

  @Environment(\.router) private var router
  @Environment(\.dismiss) private var dismiss
  @State var model: UserScreenModel

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello \(model.name)")
      Button("User: Ben") {
        router.push(AppRoute.user(name: "Ben"))
      }
      Button("Back") {
        router.back()
      }
      Button("Back (SwiftUI dismiss)") {
        // Pops the same way a swipe-back would -- logs .action(.back(count: 1)) via
        // path's didSet, same as router.back() above.
        dismiss()
      }
      Button("Pop to root") {
        router.popToRoot()
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
