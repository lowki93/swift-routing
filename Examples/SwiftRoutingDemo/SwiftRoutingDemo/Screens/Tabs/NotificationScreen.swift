//
//  NotificationScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 09/03/2025.
//

import SwiftUI

struct NotificationScreen: View {

  @Environment(\.tabRouter) private var tabRouter

  var body: some View {
    VStack {
      Button("To Home tab") {
        tabRouter?.change(tab: HomeTab.home)
      }
    }
  }
}
