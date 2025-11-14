//
//  LoggerConfiguration.swift
//  swift-routing
//
//  Created by Kevin Budain on 28/02/2025.
//

import Foundation
import OSLog

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

extension LoggerConfiguration {

  static func `default`(loggerConfiguration: LoggerConfiguration) {
    let message = switch loggerConfiguration.message {
    case .create(.none): "init"
    case let .create(from: .some(from)): "init from: '\(from)'"
    case .delete: "deninit"
    case let .navigation(from, to, type): "navigate from: '\(from)' to: '\(to)' type: \(type)"
    case let .onAppear(route): "'\(route)' appear"
    case let .onDisappear(route): "'\(route)' disappear"
    case let .context(.add(route, context)): "Add Context '\(context)' for: '\(route)"
    case let .context(.execute(context, from: route)): "send Context '\(context)' from: '\(route)"
    case let .context(.remove(route, context)): "Remove Context '\(context)' for: '\(route)"
    case .action(.popToRoot): "popToRoot"
    case .action(.close): "close"
    case .action(.back(count: .none)): "back"
    case let .action(.back(count: .some(count))): "back, count: \(count)"
    case let .action(.closeChildren(router)): "closeChildren for: '\(router)'"
    case let .action(.changeTab(tab)): "changeTab to: '\(tab)'"
    }

    Logger.default.log(
      level: OSLogType(from: .info),
      "Router: \(loggerConfiguration.router) | \(message)"
    )
  }

}
