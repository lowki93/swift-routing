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
        let message = switch loggerConfiguration.type {
        case let .create(.none): "init"
        case let .create(from: .some(from)): "init from: '\(from)'"
        case .delete: "deninit"
        case let .navigation(from, to, type): "from: '\(from)' to: '\(to)' type: \(type)"
        case let .onAppear(route): "'\(route)' appear"
        case let .onDisappear(route): "'\(route)' disappear"
        case let .context(context, route): "send '\(context)' from: '\(route)'"
        case let .action(.popToRoot): "popToRoot"
        case let .action(.close): "close"
        case let .action(.back(count: .none)): "back"
        case let .action(.back(count: .some(count))): "back, count: \(count)"
        case let .action(.closeChildren(router)): "closeChildren for: '\(router)'"
        case let .action(.changeTab(tab)): "changeTab to: '\(tab)'"
        }

        Logger.default.log(
          level: OSLogType(from: loggerConfiguration.verbosity),
          "Router: \(loggerConfiguration.router) | \(message)"
        )
      }
    )
  }
}
