import Testing
@testable import SwiftRouting

enum LogMessageKind {
  case delete
  case actionClose
  case onAppear(TestRoute)
}

@MainActor
func assertLogMessageKind(_ message: LoggerMessage?, is expected: LogMessageKind) {
  guard let message else {
    #expect(Bool(false))
    return
  }

  let matches: Bool
  switch (expected, message) {
  case (.delete, .delete):
    matches = true
  case (.actionClose, .action(.close)):
    matches = true
  case let (.onAppear(expectedRoute), .onAppear(route)):
    matches = (route as? TestRoute) == expectedRoute
  default:
    matches = false
  }

  #expect(matches)
}
