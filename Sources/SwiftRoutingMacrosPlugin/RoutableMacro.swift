//
//  RoutableMacro.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Generates `var name: String` from an enum's cases (via `RouteNameGenerator`), and
/// `var routingType: RoutingType` when at least one case carries a `@Sheet` / `@Cover`
/// marker. Also adds the `Route` conformance via extension when it isn't already declared
/// explicitly.
///
/// See `Sources/SwiftRoutingMacros/Routable.swift` for the public macro declaration and
/// user-facing documentation.
public enum RoutableMacro: MemberMacro {

  private enum RoutingTypeMarker {
    case sheet(withStack: Bool)
    case cover

    var expression: String {
      switch self {
      case .sheet(let withStack): return ".sheet(withStack: \(withStack))"
      case .cover: return ".cover"
      }
    }
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      context.diagnose(.notAnEnum("Routable"), at: node)
      return []
    }

    let nameVar = RouteNameGenerator.nameProperty(for: enumDecl, attribute: node, context: context)
    let access = enumDecl.accessModifierPrefix

    var routingTypeLines: [String] = []
    var allMarkerAttributes: [(name: String, attribute: AttributeSyntax)] = []

    for caseDecl in enumDecl.caseDecls {
      let caseMarkerAttributes = caseDecl.markerAttributes(named: markerNames)
      let marker = routingTypeMarker(from: caseMarkerAttributes, context: context)
      allMarkerAttributes += caseMarkerAttributes

      for element in caseDecl.elements {
        routingTypeLines.append("case \(element.wildcardPattern): \(marker?.expression ?? ".push")")
      }
    }

    guard !allMarkerAttributes.isEmpty else { return [nameVar] }

    if enumDecl.declaresInstanceProperty(named: "routingType") {
      for entry in allMarkerAttributes {
        context.diagnose(.markerWithHandWrittenProperty(marker: entry.name, property: "routingType"), at: entry.attribute)
      }
      return [nameVar]
    }

    let routingTypeBody = routingTypeLines.joined(separator: "\n")
    let routingTypeVar: DeclSyntax = """
      \(raw: access)var routingType: SwiftRouting.RoutingType {
        switch self {
        \(raw: routingTypeBody)
        }
      }
      """
    return [nameVar, routingTypeVar]
  }

  // MARK: - Routing type markers

  private static let markerNames: Set<String> = ["Sheet", "Cover"]

  private static func routingTypeMarker(
    from attributes: [(name: String, attribute: AttributeSyntax)],
    context: some MacroExpansionContext
  ) -> RoutingTypeMarker? {
    guard let first = attributes.first else { return nil }

    for extra in attributes.dropFirst() {
      if extra.name == first.name {
        context.diagnose(.duplicateMarker(extra.name), at: extra.attribute)
      } else {
        context.diagnose(.multipleRoutingTypeMarkers(extra: extra.name, first: first.name), at: extra.attribute)
      }
    }

    switch first.name {
    case "Cover":
      return .cover
    case "Sheet":
      guard let arg = first.attribute.arguments?.as(LabeledExprListSyntax.self)?
        .first(where: { $0.label?.text == "withStack" }) else { return .sheet(withStack: true) }
      if let literal = arg.expression.as(BooleanLiteralExprSyntax.self) {
        return .sheet(withStack: literal.literal.tokenKind == .keyword(.true))
      }
      context.diagnose(.withStackNotLiteral, at: arg.expression)
      return .sheet(withStack: true)
    default:
      return nil
    }
  }
}

// MARK: - ExtensionMacro

extension RoutableMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // `protocols` only lists conformances the compiler couldn't already resolve -- if the
    // enum already declares `: Route` explicitly, this is empty and we must add nothing
    // (an extra `extension X: Route {}` would be a redundant-conformance error).
    guard !protocols.isEmpty, declaration.is(EnumDeclSyntax.self) else { return [] }
    return [try ExtensionDeclSyntax("extension \(type.trimmed): Route {}")]
  }
}
