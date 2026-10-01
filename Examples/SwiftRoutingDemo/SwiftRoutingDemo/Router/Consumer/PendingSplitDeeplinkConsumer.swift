//
//  PendingSplitDeeplinkConsumer.swift
//  SwiftRoutingDemo
//

import SwiftRouting
import SwiftUI

// Attached to SidebarScreen -- the only column of RoutingSplitView guaranteed to be mounted
// (content/detail are conditional on a selection). `@Environment(\.router)` resolves to the
// real split Router because SidebarScreen renders inside RoutingSplitView's own environment
// scope, same as every other column.
//
// SplitScreen swaps between two *structurally different* RoutingSplitView instances depending
// on `isSplitThreeColumn`: 3-column (ContentData = PlayerType, DetailData = Player) and
// 2-column (no content column, DetailData = PlayerType). A single SplitDeeplinkHandler can't
// express both shapes at once, so this consumer picks the handler matching whichever mode is
// live right now, rather than forcing a mode switch -- the deep link works with the app's
// current column layout instead of overriding it.
struct PendingSplitDeeplinkConsumer: ViewModifier {
  @Environment(\.router) private var router
  @Environment(\.isSplitThreeColumn) private var isThreeColumn
  @Environment(PendingDeeplinkStore.self) private var pendingDeeplink
  @State private var splitHandler = SplitViewDeeplinkHandler()
  @State private var listHandler = PlayerListDeeplinkHandler()

  func body(content: Content) -> some View {
    content
      .task(id: pendingDeeplink.identifier) {
        guard case let .splitView(target) = pendingDeeplink.identifier else { return }

        if isThreeColumn.wrappedValue {
          guard let splitDeeplink = try? await splitHandler.deeplink(from: target) else {
            pendingDeeplink.identifier = nil
            return
          }
          router.handle(splitDeeplink: splitDeeplink)
        } else {
          guard case let .players(playersTarget) = target,
                let splitDeeplink = try? await listHandler.deeplink(from: playersTarget) else {
            pendingDeeplink.identifier = nil
            return
          }
          router.handle(splitDeeplink: splitDeeplink)
        }

        pendingDeeplink.identifier = nil
      }
  }
}
