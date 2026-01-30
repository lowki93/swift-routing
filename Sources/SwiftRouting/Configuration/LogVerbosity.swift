//
//  LogVerbosity.swift
//  swift-routing
//
//  Created by Kévin Budain on 3/3/25.
//

/// Defines the severity level for log messages in the routing system.
///
/// Use these levels to filter and categorize log output based on importance.
/// Maps directly to `OSLogType` levels when using the default logger configuration.
enum LogVerbosity {
  /// Informational messages about normal operation.
  case info
  /// Debug-level messages useful during development.
  case debug
  /// Error conditions that should be addressed.
  case error
  /// Critical failures that may cause system instability.
  case fault
}
