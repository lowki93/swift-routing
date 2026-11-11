//
//  TabRoutableMacro.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Generates `var name: String` from an enum's cases (via `RouteNameGenerator`), and
/// `var hideTabBarOnPush: Bool` when at least one case carries a `@HideTabBarOnPush`
/// marker. Also adds the `TabRoute` conformance via extension when it isn't already
/// declared explicitly.
///
/// See `Sources/SwiftRoutingMacros/TabRoutable.swift` for the public macro declaration and
/// user-facing documentation.
public enum TabRoutableMacro: MemberMacro {

  private static let hideMarkerName = "HideTabBarOnPush"
  private static let routingTypeMarkerNames: Set<String> = ["Sheet", "Cover"]

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      context.diagnose(.notAnEnum("TabRoutable"), at: node)
      return []
    }

    let nameVar = RouteNameGenerator.nameProperty(for: enumDecl, attribute: node, context: context)
    let access = enumDecl.accessModifierPrefix

    var hideLines: [String] = []
    var allHideAttributes: [(name: String, attribute: AttributeSyntax)] = []
    var allCasesMarked = true

    for caseDecl in enumDecl.caseDecls {
      // A tab is selected, never presented: a routing type marker can't have any effect.
      for entry in caseDecl.markerAttributes(named: routingTypeMarkerNames) {
        context.diagnose(.routingTypeMarkerInTabRoutable(entry.name), at: entry.attribute)
      }

      let caseMarkers = caseDecl.markerAttributes(named: [hideMarkerName])
      for extra in caseMarkers.dropFirst() {
        context.diagnose(.duplicateMarker(extra.name), at: extra.attribute)
      }
      allHideAttributes += caseMarkers

      let hides = !caseMarkers.isEmpty
      if !hides { allCasesMarked = false }
      for element in caseDecl.elements {
        hideLines.append("case \(element.wildcardPattern): \(hides)")
      }
    }

    guard !allHideAttributes.isEmpty else { return [nameVar] }

    if enumDecl.declaresInstanceProperty(named: "hideTabBarOnPush") {
      for entry in allHideAttributes {
        context.diagnose(
          .markerWithHandWrittenProperty(marker: entry.name, property: "hideTabBarOnPush"),
          at: entry.attribute
        )
      }
      return [nameVar]
    }

    if allCasesMarked {
      let hideVar: DeclSyntax = """
        \(raw: access)var hideTabBarOnPush: Bool {
          true
        }
        """
      return [nameVar, hideVar]
    }

    let hideBody = hideLines.joined(separator: "\n")
    let hideVar: DeclSyntax = """
      \(raw: access)var hideTabBarOnPush: Bool {
        switch self {
        \(raw: hideBody)
        }
      }
      """
    return [nameVar, hideVar]
  }
}

// MARK: - ExtensionMacro

extension TabRoutableMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // `protocols` only lists conformances the compiler couldn't already resolve -- if the
    // enum already declares `: TabRoute` explicitly, this is empty and we must add nothing.
    guard !protocols.isEmpty, declaration.is(EnumDeclSyntax.self) else { return [] }
    return [try ExtensionDeclSyntax("extension \(type.trimmed): TabRoute {}")]
  }
}
