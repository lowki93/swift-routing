//
//  AboutScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 12/08/2026.
//

import SwiftRouting
import SwiftUI

struct AboutScreen: View {

  @Environment(\.router) private var router
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "info.circle")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Presented with router.cover(_:)")
      Button("Close") { router.close() }
      Button("Close (SwiftUI dismiss)") {
        // Clears the parent's cover the same way swipe-down/tap-outside would --
        // logs .action(.close) via cover's didSet, same as router.close() above.
        dismiss()
      }
    }
    .padding()
  }
}
