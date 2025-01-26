//
//  DismissModifier.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 27/01/2025.
//

import SwiftUI

struct DismissModifier: ViewModifier {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router

  func body(content: Content) -> some View {
    content
      .onChange(of: router.triggerDismiss) { triggerDismiss in
        guard triggerDismiss else { return }
        dismiss()
      }
  }
}
