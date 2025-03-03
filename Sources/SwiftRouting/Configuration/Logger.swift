//
//  Logger.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import OSLog

extension Logger {
  static let `default` = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Package",
    category: "swift-routing"
  )
}

extension OSLogType {
  init(from verbosity: LogVerbosity) {
    switch verbosity {
    case .debug: self = .debug
    case .info: self = .info
    case .error: self = .error
    case .fault:  self = .fault
    }
  }
}
