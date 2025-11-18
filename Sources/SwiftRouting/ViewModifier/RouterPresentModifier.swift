//
//  RouterPresentModifier.swift
//  swift-routing
//
//  Created by Kévin Budain on 11/6/25.
//

import SwiftUI

public struct RouterPresentModifier: ViewModifier {

  @Environment(\.router) private var router: Router
  let perform: (Bool) -> Void

  public func body(content: Content) -> some View {
    content.onReceive(router.presentPublished, perform: perform)
  }
}

public extension View {
  func routerPresent(perform: @escaping (Bool) -> Void) -> some View {
    self.modifier(RouterPresentModifier(perform: perform))
  }
}
