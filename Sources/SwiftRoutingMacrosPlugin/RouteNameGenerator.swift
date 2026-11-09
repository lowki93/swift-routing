//
//  RouteNameGenerator.swift
//  swift-routing
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Generates `var name: String` for an enum. Shared by `RoutableMacro` and `TabRoutableMacro`
/// so both macros produce identical names and identical `@RouteName` / `nameStyle` diagnostics.
enum RouteNameGenerator {

  private enum NameStyle {
    case verbatim
    case capitalized
  }

  static func nameProperty(
    for enumDecl: EnumDeclSyntax,
    attribute node: AttributeSyntax,
    context: some MacroExpansionContext
  ) -> DeclSyntax {
    let style = nameStyle(from: node, context: context)
    let access = enumDecl.accessModifierPrefix

    var lines: [String] = []

    for caseDecl in enumDecl.caseDecls {
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
          line = defaultLine(for: element, style: style)
        } else if let attribute = routeNameAttribute,
                  let firstArg = attribute.arguments?.as(LabeledExprListSyntax.self)?.first {
          line = resolvedLine(
            element: element,
            for: firstArg.expression,
            caseName: caseName,
            params: params,
            bindings: bindings,
            style: style,
            attribute: attribute,
            context: context
          )
        } else {
          line = defaultLine(for: element, style: style)
        }

        lines.append(line)
      }
    }

    let switchBody = lines.joined(separator: "\n")
    return """
      \(raw: access)var name: String {
        switch self {
        \(raw: switchBody)
        }
      }
      """
  }

  // MARK: - nameStyle

  private static func nameStyle(from node: AttributeSyntax, context: some MacroExpansionContext) -> NameStyle {
    guard let args = node.arguments?.as(LabeledExprListSyntax.self),
          let arg = args.first(where: { $0.label?.text == "nameStyle" }) else { return .verbatim }

    if let member = arg.expression.as(MemberAccessExprSyntax.self), member.base == nil {
      switch member.declName.baseName.text {
      case "verbatim": return .verbatim
      case "capitalized": return .capitalized
      default: break
      }
    }

    context.diagnose(.invalidNameStyle, at: arg.expression)
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

  private static func defaultLine(for element: EnumCaseElementSyntax, style: NameStyle) -> String {
    let pattern = element.wildcardPattern
    let body = "\"" + formatted(element.name.text, style: style) + "\""
    return "case \(pattern): \(body)"
  }

  private static func resolvedLine(
    element: EnumCaseElementSyntax,
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
        element: element,
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
        element: element,
        caseName: caseName,
        params: params,
        bindings: bindings,
        style: style,
        attribute: attribute,
        context: context
      )
    }

    context.diagnose(.argumentNotStringLiteral, at: expr)
    return defaultLine(for: element, style: style)
  }

  private static func templateLine(
    element: EnumCaseElementSyntax,
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
        return defaultLine(for: element, style: style)
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
    element: EnumCaseElementSyntax,
    caseName: String,
    params: [EnumCaseParameterListSyntax.Element],
    bindings: [String],
    style: NameStyle,
    attribute: AttributeSyntax,
    context: some MacroExpansionContext
  ) -> String {
    guard params.count == 1, let bindingName = bindings.first else {
      context.diagnose(.delegateArityMismatch, at: attribute)
      return defaultLine(for: element, style: style)
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
