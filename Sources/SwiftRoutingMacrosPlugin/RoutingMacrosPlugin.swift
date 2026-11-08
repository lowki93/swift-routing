//
//  RoutingMacrosPlugin.swift
//  swift-routing
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RoutingMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    RoutableMacro.self,
    RouteNameMacro.self,
  ]
}
