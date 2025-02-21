//
//  Configuration.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import OSLog

public struct Configuration {

  let loggerAction: [LoggerAction]
  let logger: ((Router, String?, [String: Any]?) -> Void)?

  public init(
    loggerAction: [LoggerAction],
    logger: ((Router, String?, [String: Any]?) -> Void)?
  ) {
    self.loggerAction = loggerAction
    self.logger = logger
  }
}

extension Configuration {
  static var `default`: Configuration {
    Configuration(
      loggerAction: LoggerAction.allCases,
      logger: { router, message, metadata in
        let messageString = if let message { message + " " } else { "" }
        let metadataString = metadata?.map { "\($0): '\($1)'" }.joined(separator: ", ") ?? ""

        Logger.default.debug("Router: \(router.type) | \(messageString)\(metadataString)")
      }
    )
  }
}
