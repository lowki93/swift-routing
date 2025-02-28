//
//  Configuration.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import OSLog

/// A configuration structure used to initialize the app router.
///
/// `Configuration` allows customization of the logging behavior for routing actions.
/// It provides a closure that receives `LoggerConfiguration` and can be used to log
/// navigation events.
///
/// ## Properties
/// - `logger`: A closure that takes a `LoggerConfiguration` and logs routing actions.
///
/// ## Default Configuration
/// `Configuration.default` provides a predefined logging behavior using `OSLog`.
public struct Configuration {
  /// Closure used for logging routing actions.
  let logger: ((LoggerConfiguration) -> Void)?

  /// Initializes a new configuration instance.
  ///
  /// - Parameter logger: A closure that receives `LoggerConfiguration` for logging purposes.
  public init(logger: ((LoggerConfiguration) -> Void)?) {
    self.logger = logger
  }
}

extension Configuration {
  /// The default configuration with built-in logging using `OSLog`.
  ///
  /// Logs router actions, including type, message, and metadata.
  static var `default`: Configuration {
    Configuration(
      logger: { loggerConfiguration in
        let messageString = if let message = loggerConfiguration.message { message + " " } else { "" }
        let metadataString = loggerConfiguration.metadata?.map { "\($0): '\($1)'" }.joined(separator: ", ") ?? ""

        Logger.default.debug("Router: \(loggerConfiguration.router.type) | \(messageString)\(metadataString)")
      }
    )
  }
}
