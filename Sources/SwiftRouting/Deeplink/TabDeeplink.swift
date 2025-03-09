//
//  TabDeeplink.swift
//  swift-routing
//
//  Created by Kevin Budain on 09/03/2025.
//

public struct TabDeeplink<Tab: TabRoute, R: Route> {
  let tab: Tab
  let deeplink: DeeplinkRoute<R>?

  public init(tab: Tab, deeplink: DeeplinkRoute<R>?) {
    self.tab = tab
    self.deeplink = deeplink
  }
}
