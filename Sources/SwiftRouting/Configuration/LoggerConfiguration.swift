//
//  LoggerConfiguration.swift
//  swift-routing
//
//  Created by Kevin Budain on 28/02/2025.
//

/// A configuration structure that encapsulates logging details for router actions.
///
/// `LoggerConfiguration` provides metadata about actions performed by a `Router`,
/// allowing better debugging and tracking of navigation events.
///
/// ## Properties
/// - `type`: The type of action performed by the router.
/// - `router`: The router instance that executed the action.
/// - `message`: An optional message describing the action.
/// - `metadata`: Additional metadata containing context-specific information about the router or action.
///
/// This struct is useful for debugging and analytics purposes within the `swift-routing` framework.
public struct LoggerConfiguration {
  /// The type of action performed by the router.
  let type: LoggerAction

  let verbosity: LogVerbosity

  /// The router instance that performed the action.
  let router: BaseRouter

  /// An optional message providing additional context about the action.
  let message: String?

  /// Additional metadata containing context-specific details about the router or action.
  let metadata: [String: Any]?
}
