//
//  RoutableMacro.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Generates `var name: String` from an enum's cases, and adds the `Route` conformance
/// via extension when it isn't already declared explicitly.
///
/// See `Sources/SwiftRouting/Macros/Routable.swift` for the public macro declaration and
/// user-facing documentation.
public enum RoutableMacro: MemberMacro {

  private enum NameStyle {
    case verbatim
    case capitalized
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      context.diagnose(.notAnEnum, at: node)
      return []
    }

    let style = nameStyle(from: node)
    let access = accessModifier(of: enumDecl)

    var lines: [String] = []

    for member in enumDecl.memberBlock.members {
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }

      let routeNameAttribute = caseDecl.attributes
        .compactMap { $0.as(AttributeSyntax.self) }
        .first { $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "RouteName" }

      let hasMultipleElements = caseDecl.elements.count > 1
      if routeNameAttribute != nil, hasMultipleElements {
        context.diagnose(.multipleElements, at: caseDecl)
      }

      for element in caseDecl.elements {
        let caseName = element.name.text
        let params = Array(element.parameterClause?.parameters ?? [])
        let bindings = bindingNames(for: params)

        let line: String
        if hasMultipleElements {
          line = defaultLine(caseName: caseName, paramCount: params.count, style: style)
        } else if let attribute = routeNameAttribute,
                  let firstArg = attribute.arguments?.as(LabeledExprListSyntax.self)?.first {
          line = resolvedLine(
            for: firstArg.expression,
            caseName: caseName,
            params: params,
            bindings: bindings,
            style: style,
            attribute: attribute,
            context: context
          )
        } else {
          line = defaultLine(caseName: caseName, paramCount: params.count, style: style)
        }

        lines.append(line)
      }
    }

    let switchBody = lines.joined(separator: "\n")
    let nameVar: DeclSyntax = """
      \(raw: access)var name: String {
        switch self {
        \(raw: switchBody)
        }
      }
      """
    return [nameVar]
  }

  // MARK: - nameStyle

  private static func nameStyle(from node: AttributeSyntax) -> NameStyle {
    guard let args = node.arguments?.as(LabeledExprListSyntax.self) else { return .verbatim }
    for arg in args where arg.label?.text == "nameStyle" {
      if let member = arg.expression.as(MemberAccessExprSyntax.self), member.declName.baseName.text == "capitalized" {
        return .capitalized
      }
    }
    return .verbatim
  }

  private static func formatted(_ caseName: String, style: NameStyle) -> String {
    switch style {
    case .verbatim:
      return caseName
    case .capitalized:
      guard let first = caseName.first else { return caseName }
      return first.uppercased() + caseName.dropFirst()
    }
  }

  // MARK: - Access level

  private static func accessModifier(of enumDecl: EnumDeclSyntax) -> String {
    for modifier in enumDecl.modifiers {
      switch modifier.name.tokenKind {
      case .keyword(.public): return "public "
      case .keyword(.package): return "package "
      default: continue
      }
    }
    return ""
  }

  // MARK: - Bindings

  private static func bindingNames(for params: [EnumCaseParameterListSyntax.Element]) -> [String] {
    params.enumerated().map { index, param in
      if let label = param.firstName, label.text != "_" {
        return label.text
      }
      return "arg\(index)"
    }
  }

  private static func casePattern(caseName: String, params: [EnumCaseParameterListSyntax.Element], bindings: [String], referenced: Set<String>) -> String {
    guard !params.isEmpty else { return ".\(caseName)" }
    let parts = bindings.map { referenced.contains($0) ? "let \($0)" : "_" }
    return ".\(caseName)(\(parts.joined(separator: ", ")))"
  }

  // MARK: - Line generation

  private static func defaultLine(caseName: String, paramCount: Int, style: NameStyle) -> String {
    let pattern = paramCount == 0
      ? ".\(caseName)"
      : ".\(caseName)(\(Array(repeating: "_", count: paramCount).joined(separator: ", ")))"
    let body = "\"" + formatted(caseName, style: style) + "\""
    return "case \(pattern): \(body)"
  }

  private static func resolvedLine(
    for expr: ExprSyntax,
    caseName: String,
    params: [EnumCaseParameterListSyntax.Element],
    bindings: [String],
    style: NameStyle,
    attribute: AttributeSyntax,
    context: some MacroExpansionContext
  ) -> String {
    if let stringLiteral = expr.as(StringLiteralExprSyntax.self) {
      return templateLine(
        stringLiteral: stringLiteral,
        caseName: caseName,
        params: params,
        bindings: bindings,
        style: style,
        attribute: attribute,
        context: context
      )
    }

    if let memberAccess = expr.as(MemberAccessExprSyntax.self),
       memberAccess.base == nil,
       memberAccess.declName.baseName.text == "delegate" {
      return delegateLine(
        caseName: caseName,
        params: params,
        bindings: bindings,
        style: style,
        attribute: attribute,
        context: context
      )
    }

    context.diagnose(.argumentNotStringLiteral, at: expr)
    return defaultLine(caseName: caseName, paramCount: params.count, style: style)
  }

  private static func templateLine(
    stringLiteral: StringLiteralExprSyntax,
    caseName: String,
    params: [EnumCaseParameterListSyntax.Element],
    bindings: [String],
    style: NameStyle,
    attribute: AttributeSyntax,
    context: some MacroExpansionContext
  ) -> String {
    var rawText = ""
    for segment in stringLiteral.segments {
      guard let stringSegment = segment.as(StringSegmentSyntax.self) else {
        // Not a raw string literal (real interpolation) -- unsupported, see RouteNameTemplate docs.
        context.diagnose(.argumentNotStringLiteral, at: stringLiteral)
        return defaultLine(caseName: caseName, paramCount: params.count, style: style)
      }
      rawText += stringSegment.content.text
    }

    let bindingSet = Set(bindings)
    let referenced = referencedIdentifiers(in: rawText)
    for identifier in referenced where !bindingSet.contains(identifier) {
      context.diagnose(.unknownBinding(identifier, available: bindings), at: attribute)
    }

    let pattern = casePattern(caseName: caseName, params: params, bindings: bindings, referenced: Set(referenced))
    let body = "\"" + rawText + "\""
    return "case \(pattern): \(body)"
  }

  private static func delegateLine(
    caseName: String,
    params: [EnumCaseParameterListSyntax.Element],
    bindings: [String],
    style: NameStyle,
    attribute: AttributeSyntax,
    context: some MacroExpansionContext
  ) -> String {
    guard params.count == 1, let bindingName = bindings.first else {
      context.diagnose(.delegateArityMismatch, at: attribute)
      return defaultLine(caseName: caseName, paramCount: params.count, style: style)
    }

    let prefix = formatted(caseName, style: style)
    let pattern = ".\(caseName)(let \(bindingName))"
    let body = "\"" + prefix + ".\\(" + bindingName + ".name)\""
    return "case \(pattern): \(body)"
  }

  // MARK: - Template identifier scan (heuristic)

  /// Returns the leading identifier of every `\(...)` interpolation found in `text`
  /// (e.g. `arg0` in `\(arg0.name)`). Does not parse or type-check the rest of each
  /// interpolated expression -- see the `@RouteName` documentation for the limits this implies.
  private static func referencedIdentifiers(in text: String) -> [String] {
    var result: [String] = []
    let chars = Array(text)
    var i = 0
    while i < chars.count {
      if chars[i] == "\\", i + 1 < chars.count, chars[i + 1] == "(" {
        var depth = 1
        var j = i + 2
        let innerStart = j
        while j < chars.count, depth > 0 {
          if chars[j] == "(" { depth += 1 }
          else if chars[j] == ")" { depth -= 1 }
          if depth > 0 { j += 1 }
        }
        let inner = String(chars[innerStart..<min(j, chars.count)])
        if let identifier = leadingIdentifier(in: inner) {
          result.append(identifier)
        }
        i = j + 1
      } else {
        i += 1
      }
    }
    return result
  }

  private static func leadingIdentifier(in text: String) -> String? {
    var slice = Substring(text)
    while let first = slice.first, first == " " || first == "\t" {
      slice = slice.dropFirst()
    }
    guard let first = slice.first, first.isLetter || first == "_" else { return nil }
    var identifier = String(first)
    slice = slice.dropFirst()
    while let next = slice.first, next.isLetter || next.isNumber || next == "_" {
      identifier.append(next)
      slice = slice.dropFirst()
    }
    return identifier
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
