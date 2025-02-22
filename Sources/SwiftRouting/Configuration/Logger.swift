//
//  Logger.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import OSLog

public typealias LogMessage = OSLogMessage

extension Logger {
  static let `default` = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Package",
    category: "swift-routing"
  )
}
