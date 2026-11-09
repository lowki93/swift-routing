//
//  CoverMacro.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Marker peer macro -- expands to nothing. `RoutableMacro` reads the attribute directly
/// from the enum case's attribute list to generate `routingType`; this type only needs to
/// exist so `@Cover` is legal syntax on a case declaration.
public enum CoverMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if declaration.as(EnumCaseDeclSyntax.self) == nil {
      context.diagnose(.notACase("Cover"), at: node)
    }
    return []
  }
}
