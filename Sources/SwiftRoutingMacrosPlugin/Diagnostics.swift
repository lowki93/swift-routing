//
//  Diagnostics.swift
//  swift-routing
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct RoutableDiagnostic: DiagnosticMessage {
  let message: String
  let diagnosticID: MessageID
  let severity: DiagnosticSeverity

  private init(_ id: String, _ message: String, severity: DiagnosticSeverity = .error) {
    self.message = message
    self.diagnosticID = MessageID(domain: "SwiftRoutingMacros", id: id)
    self.severity = severity
  }

  static func notAnEnum(_ macroName: String) -> RoutableDiagnostic {
    RoutableDiagnostic(
      "notAnEnum",
      "'@\(macroName)' can only be applied to an enum"
    )
  }

  static let invalidNameStyle = RoutableDiagnostic(
    "invalidNameStyle",
    "'nameStyle' must be a literal `.verbatim` or `.capitalized`"
  )

  static func notACase(_ macroName: String) -> RoutableDiagnostic {
    RoutableDiagnostic(
      "notACase",
      "'@\(macroName)' can only be applied to an enum case"
    )
  }

  static let multipleElements = RoutableDiagnostic(
    "multipleElements",
    "'@RouteName' cannot be applied to a case declaration with multiple elements (`case a, b`) -- split them into separate cases"
  )

  static let argumentNotStringLiteral = RoutableDiagnostic(
    "argumentNotStringLiteral",
    "'@RouteName' expects a raw string literal (`#\"...\"#`) or `.delegate`"
  )

  static func unknownBinding(_ name: String, available: [String]) -> RoutableDiagnostic {
    let list = available.isEmpty ? "none" : available.joined(separator: ", ")
    return RoutableDiagnostic(
      "unknownBinding",
      "'\(name)' is not an associated value of this case. Available: \(list)"
    )
  }

  static let delegateArityMismatch = RoutableDiagnostic(
    "delegateArityMismatch",
    "'@RouteName(.delegate)' requires exactly one associated value on this case"
  )

  static func multipleRoutingTypeMarkers(extra: String, first: String) -> RoutableDiagnostic {
    RoutableDiagnostic(
      "multipleRoutingTypeMarkers",
      "'@\(extra)' conflicts with '@\(first)' on the same case -- a case can have only one routing type marker"
    )
  }

  static func duplicateMarker(_ name: String) -> RoutableDiagnostic {
    RoutableDiagnostic(
      "duplicateMarker",
      "'@\(name)' is applied more than once to this case"
    )
  }

  static let withStackNotLiteral = RoutableDiagnostic(
    "withStackNotLiteral",
    "'withStack' must be a literal `true` or `false`"
  )

  static func markerWithHandWrittenProperty(marker: String, property: String) -> RoutableDiagnostic {
    RoutableDiagnostic(
      "markerWithHandWrittenProperty",
      "'@\(marker)' cannot be combined with a hand-written '\(property)' -- remove the marker or the property"
    )
  }

  static let hideTabBarOnPushOutsideTabRoutable = RoutableDiagnostic(
    "hideTabBarOnPushOutsideTabRoutable",
    "'@HideTabBarOnPush' can only be applied to a case of a '@TabRoutable' enum"
  )

  static func routingTypeMarkerInTabRoutable(_ marker: String) -> RoutableDiagnostic {
    RoutableDiagnostic(
      "routingTypeMarkerInTabRoutable",
      "'@\(marker)' cannot be used in a '@TabRoutable' enum -- a tab is selected, never presented"
    )
  }
}

extension MacroExpansionContext {
  func diagnose(_ message: RoutableDiagnostic, at node: some SyntaxProtocol) {
    diagnose(Diagnostic(node: Syntax(node), message: message))
  }
}
