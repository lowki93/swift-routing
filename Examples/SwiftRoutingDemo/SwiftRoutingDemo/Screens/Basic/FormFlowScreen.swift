//
//  FormFlowScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 13/08/2026.
//

import SwiftRouting
import SwiftUI

struct FormFlowScreen: View {

  @Environment(\.router) private var router
  @State var model: FormFlowScreenModel

  var body: some View {
    VStack(spacing: 16) {
      if let result = model.lastResult {
        Text("Name: \(result.name)")
        Text("Age: \(result.age)")
        Text("Newsletter: \(result.newsletter ? "yes" : "no")")
      } else {
        Text("No submission yet")
      }

      Button("Open form (push)") { router.push(AppRoute.form) }
      Button("Open form (sheet)") { router.present(AppRoute.form) }
    }
    .navigationTitle("Form flow")
    // Same FormScreen, opened two different ways -- terminate() resolves to a stack pop
    // when pushed and to close() when presented, without FormScreen knowing which.
    .routerContext(FormResult.self) { [weak model] in
      model?.lastResult = $0
    }
  }
}

@Observable @MainActor
final class FormFlowScreenModel {
  var lastResult: FormResult?

  init() {}
}
