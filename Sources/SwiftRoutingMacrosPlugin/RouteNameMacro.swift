//
//  RouteNameMacro.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Marker peer macro -- expands to nothing. `RoutableMacro` reads its argument directly
/// from the enum case's attribute list; this type only needs to exist so `@RouteName(...)`
/// is legal syntax on a case declaration.
public enum RouteNameMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if declaration.as(EnumCaseDeclSyntax.self) == nil {
      context.diagnose(.notACase("RouteName"), at: node)
    }
    return []
  }
}
