//
//  OnFirstAppearModifier.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 05/04/2026.
//

import SwiftUI

private struct OnFirstAppearViewModifier: ViewModifier {
  let perform: () -> Void

  @State private var firstTime = true

  func body(content: Content) -> some View {
    content
      .onAppear {
        guard firstTime else { return }
        firstTime = false
        perform()
      }
  }
}

extension View {
  func onFirstAppear(perform: @escaping () -> Void) -> some View {
    modifier(OnFirstAppearViewModifier(perform: perform))
  }
}
