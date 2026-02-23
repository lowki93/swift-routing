import SwiftRouting
import Foundation

final class LoggerSpy {
  private let storesConfiguration: Bool
  var receivedLoggerConfiguration: LoggerConfiguration?
  var receivedMessage: LoggerMessage?
  var receivedRouterId: UUID?

  init(storesConfiguration: Bool = true) {
    self.storesConfiguration = storesConfiguration
  }

  func receive(_ loggerConfiguration: LoggerConfiguration) {
    receivedMessage = loggerConfiguration.message
    receivedRouterId = loggerConfiguration.router.id
    if storesConfiguration {
      receivedLoggerConfiguration = loggerConfiguration
    }
  }
}

extension Configuration {

  init(loggerSpy: LoggerSpy) {
    self.init(
      logger: { loggerSpy.receive($0) },
      shouldCrashOnRouteNotFound: false
    )
  }

  init() {
    self.init(logger: nil, shouldCrashOnRouteNotFound: false)
  }
}
