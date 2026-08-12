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

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "info.circle")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Presented with router.cover(_:)")
      Button("Close") { router.close() }
    }
    .padding()
  }
}
