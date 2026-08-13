//
//  FormScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 13/08/2026.
//

import SwiftRouting
import SwiftUI

struct FormScreen: View {

  @Environment(\.router) private var router
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var age = 18
  @State private var newsletter = false

  private var canTerminate: Bool {
    router.canTerminate(FormResult.self)
  }

  var body: some View {
    Form {
      TextField("Name", text: $name)
      Stepper("Age: \(age)", value: $age, in: 0...120)
      Toggle("Newsletter", isOn: $newsletter)

      if !canTerminate {
        Text("No listener — submission disabled")
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("New entry")
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          router.terminate(FormResult(name: name, age: age, newsletter: newsletter))
        }
        .disabled(name.isEmpty || !canTerminate)
      }
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
      }
    }
  }
}
