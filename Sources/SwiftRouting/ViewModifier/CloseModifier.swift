//
//  CloseModifier.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 27/01/2025.
//

import SwiftUI

struct CloseModifier: ViewModifier {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router

  func body(content: Content) -> some View {
    content
      .onReceive(router.$triggerClose) { triggerClose in
        guard triggerClose else { return }
        dismiss()
      }
  }
}
