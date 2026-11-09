//
//  HideTabBarOnPushMacro.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Marker peer macro -- expands to nothing. `TabRoutableMacro` reads the attribute directly
/// from the enum case's attribute list to generate `hideTabBarOnPush`. Unlike `@Sheet`, a
/// misplaced marker is an error here: it would otherwise leave the tab bar visible silently.
public enum HideTabBarOnPushMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(EnumCaseDeclSyntax.self) else {
      context.diagnose(.notACase("HideTabBarOnPush"), at: node)
      return []
    }

    // The first lexical context of a case is its enclosing enum, attributes included.
    // When there is none (e.g. the expansion is not hosted by a compiler), stay silent
    // rather than raise a false positive.
    if let enclosing = context.lexicalContext.first?.as(EnumDeclSyntax.self),
       !enclosing.hasAttribute(named: "TabRoutable") {
      context.diagnose(.hideTabBarOnPushOutsideTabRoutable, at: node)
    }
    return []
  }
}
