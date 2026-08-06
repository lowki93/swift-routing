//
//  Configuration.swift
//  swift-routing
//
//  Created by Kévin Budain on 2/21/25.
//

import Combine
import Foundation

/// A configuration structure used to initialize the app router.
///
/// `Configuration` allows customization of the logging behavior for routing actions.
/// It provides a closure that receives `LoggerConfiguration` and can be used to log
/// navigation events.
///
/// ## Where to Apply Configuration
/// Create and inject a configured root router at app entry point:
/// ```swift
/// @main
/// struct DemoApp: App {
///   var body: some Scene {
///     WindowGroup {
///       RoutingView(destination: HomeRoute.self, root: .home)
///         .environment(
///           \.router,
///           Router(configuration: Configuration(shouldCrashOnRouteNotFound: true))
///         )
///     }
///   }
/// }
/// ```
///
/// ## Properties
/// - `logger`: A closure that takes a `LoggerConfiguration` and logs routing actions.
///
/// ## Default Configuration
/// `Configuration.default` provides a predefined logging behavior using `OSLog`.
public struct Configuration {
  /// Closure used for logging routing actions.
  let logger: ((LoggerConfiguration) -> Void)?

  let shouldCrashOnRouteNotFound: Bool

  /// Fires when a router sharing this configuration logs a message that's worth re-checking
  /// the tree for, regardless of where that router sits in the hierarchy. Carries no payload
  /// -- it's a "something changed, re-check the tree" signal, not the event itself (see
  /// `BaseRouter.log(_:)` for why the event's `LoggerConfiguration`/router is deliberately
  /// not forwarded here).
  ///
  /// Not every logged message fires this signal -- see `LoggerMessage.shouldTriggerEvent`
  /// for exactly which ones are filtered out to avoid noisy or duplicate signals.
  ///
  /// `Configuration` is a value type, but `PassthroughSubject` is a reference type, so every
  /// router created from this configuration (directly or via a parent) shares the same
  /// publisher. Unlike `logger`, subscribing here doesn't replace or interfere with whatever
  /// the app already configured for `logger`.
  let events = PassthroughSubject<Void, Never>()

  /// Initializes a new configuration instance.
  ///
  /// - Parameters:
  ///   - logger: A closure that receives `LoggerConfiguration` for logging purposes.
  ///   - shouldCrashOnRouteNotFound: If `true`, the app will crash when a route cannot be found. Useful for catching routing errors during development.
  public init(logger: ((LoggerConfiguration) -> Void)?, shouldCrashOnRouteNotFound: Bool) {
    self.logger = logger
    self.shouldCrashOnRouteNotFound = shouldCrashOnRouteNotFound
  }

  public init(shouldCrashOnRouteNotFound: Bool) {
    self.init(
      logger: LoggerConfiguration.default(loggerConfiguration:),
      shouldCrashOnRouteNotFound: shouldCrashOnRouteNotFound
    )
  }
}

extension Configuration {
  /// The default configuration with built-in logging using `OSLog`.
  ///
  /// Logs router actions, including type, message, and metadata.
  public static var `default`: Configuration {
    Configuration(
      logger: LoggerConfiguration.default(loggerConfiguration:),
      shouldCrashOnRouteNotFound: false
    )
  }
}

extension Configuration: CustomStringConvertible {

  public var description: String {
    "configuration(crashOnRouteNotFound: \(shouldCrashOnRouteNotFound))"
  }
}
