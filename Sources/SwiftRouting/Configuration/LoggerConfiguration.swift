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
/// - `message`: The type of message performed by the router.
/// - `router`: The router instance that executed the action.
///
/// This struct is useful for debugging and analytics purposes within the `swift-routing` framework.
public struct LoggerConfiguration {
  /// The type of messageperformed by the router.
  public let message: LoggerMessage

  /// The router instance that performed the action.
  public let router: BaseRouter
}
