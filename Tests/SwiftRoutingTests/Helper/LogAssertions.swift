import Testing
@testable import SwiftRouting

typealias LogMessageKind = LoggerMessage

@MainActor
func assertLogMessageKind(_ loggerSpy: LoggerSpy, is expected: LogMessageKind) {
  guard let message = loggerSpy.receivedLoggerConfiguration?.message ?? loggerSpy.receivedMessage else {
    #expect(Bool(false))
    return
  }

  let matches: Bool
  switch (expected, message) {
  case (.delete, .delete):
    matches = true
  case let (.onAppear(expectedRoute), .onAppear(route)):
    matches = expectedRoute.hashValue == route.hashValue
  case let (.onDisappear(expectedRoute), .onDisappear(route)):
    matches = expectedRoute.hashValue == route.hashValue
  case let (.action(expectedAction), .action(action)):
    matches = assertAction(expectedAction, action)
  case let (.context(expectedContext), .context(context)):
    matches = assertContext(expectedContext, context)
  case let (.navigation(from: expectedFrom, to: expectedTo, type: expectedType), .navigation(from: from, to: to, type: type)):
    matches = expectedFrom.hashValue == from.hashValue
      && expectedTo.hashValue == to.hashValue
      && assertRoutingType(expectedType, type)
  case (.create, .create):
    matches = true
  default:
    matches = false
  }

  #expect(matches)
}

@MainActor
func assertLogMessagesContain(_ loggerSpy: LoggerSpy, expected: LogMessageKind) {
  let found = loggerSpy.receivedMessages.contains { message in
    matchesLogMessage(expected: expected, actual: message)
  }
  #expect(found)
}

private func matchesLogMessage(expected: LogMessageKind, actual: LoggerMessage) -> Bool {
  switch (expected, actual) {
  case (.delete, .delete):
    return true
  case let (.onAppear(expectedRoute), .onAppear(route)):
    return expectedRoute.hashValue == route.hashValue
  case let (.onDisappear(expectedRoute), .onDisappear(route)):
    return expectedRoute.hashValue == route.hashValue
  case let (.action(expectedAction), .action(action)):
    return assertAction(expectedAction, action)
  case let (.context(expectedContext), .context(context)):
    return assertContext(expectedContext, context)
  case let (.navigation(from: expectedFrom, to: expectedTo, type: expectedType), .navigation(from: from, to: to, type: type)):
    return expectedFrom.hashValue == from.hashValue
      && expectedTo.hashValue == to.hashValue
      && assertRoutingType(expectedType, type)
  case (.create, .create):
    return true
  default:
    return false
  }
}

private func assertRoutingType(_ expected: RoutingType, _ actual: RoutingType) -> Bool {
  switch (expected, actual) {
  case (.root, .root):
    true
  case (.push, .push):
    true
  case (.cover, .cover):
    true
  case let (.sheet(withStack: expectedWithStack), .sheet(withStack: withStack)):
    expectedWithStack == withStack
  default:
    false
  }
}

private func assertAction(_ expected: LoggerMessage.Action, _ actual: LoggerMessage.Action) -> Bool {
  switch (expected, actual) {
  case (.popToRoot, .popToRoot):
    true
  case (.close, .close):
    true
  case let (.back(expectedCount), .back(count)):
    expectedCount == count
  case let (.closeChildren(expectedRouter), .closeChildren(router)):
    expectedRouter.id == router.id
  case let (.changeTab(expectedTab), .changeTab(tab)):
    expectedTab.type == tab.type
  default:
    false
  }
}

private func assertContext(_ expected: LoggerMessage.Context, _ actual: LoggerMessage.Context) -> Bool {
  switch (expected, actual) {
  case let (.add(expectedRoute, expectedContext), .add(route, context)):
    expectedRoute.hashValue == route.hashValue && expectedContext == context
  case let (.execute(expectedContext, from: expectedRoute), .execute(context, from: route)):
    expectedContext.hashValue == context.hashValue && expectedRoute.hashValue == route.hashValue
  case let (.remove(expectedRoute, expectedContext), .remove(route, context)):
    expectedRoute.hashValue == route.hashValue && expectedContext == context
  default:
    false
  }
}
