//
//  SheetMacro.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Marker peer macro -- expands to nothing. `RoutableMacro` reads the attribute directly
/// from the enum case's attribute list to generate `routingType`; this type only needs to
/// exist so `@Sheet` is legal syntax on a case declaration.
public enum SheetMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if declaration.as(EnumCaseDeclSyntax.self) == nil {
      context.diagnose(.notACase("Sheet"), at: node)
    }
    return []
  }
}
