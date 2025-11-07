//
//  RouterPresentModifier.swift
//  swift-routing
//
//  Created by Kévin Budain on 11/6/25.
//

import SwiftUI

public struct RouterPresentModifier: ViewModifier {

  let router: Router?
  let perform: (Bool, Router) -> Void

  public func body(content: Content) -> some View {
    if let router {
      content.onReceive(router.$present) { perform($0, router) }
    } else {
      content
    }
  }
}

public extension View {
  func routerPresent(_ router: Router?, perform: @escaping (Bool, Router) -> Void) -> some View {
    self.modifier(RouterPresentModifier(router: router, perform: perform))
  }
}
