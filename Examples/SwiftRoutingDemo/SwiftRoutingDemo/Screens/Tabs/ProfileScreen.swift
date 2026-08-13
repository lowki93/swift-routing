//
//  ProfileScreen.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 07/03/2025.
//

import SwiftRouting
import SwiftUI

struct ProfileScreen: View {

  @Environment(\.router) private var router
  @Environment(\.tabRouter) private var tabRouter
  @State private var reselectionCount = 0

  var body: some View {
    VStack {
      // .profile's hideTabBarOnPush is false, so the tab bar stays visible on push.
      Button("Push user") { router.push(AppRoute.user(name: "Me")) }

      if let tabRouter {
        Button("Present search (current tab)") { tabRouter.present(AppRoute.search) }
        Button("Cover about (current tab)") { tabRouter.cover(AppRoute.about) }
        Button("Present search in notifications tab") { tabRouter.present(AppRoute.search, in: HomeTab.notifications) }
        // popToRoot(in:) does NOT call change(tab:) -- unlike push/present/cover/update,
        // this resets the home tab's stack without switching you to it.
        Button("Reset home tab (stays on profile)") { tabRouter.popToRoot(in: HomeTab.home) }
      }

      Text("Reselected \(reselectionCount) time(s)")
    }
    .navigationTitle("Profile")
    .onTabReselected(HomeTab.profile) {
      reselectionCount += 1
    }
  }
}
