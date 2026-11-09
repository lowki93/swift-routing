//
//  SyntaxHelpers.swift
//  swift-routing
//

import SwiftSyntax

extension EnumDeclSyntax {
  /// `"public "`, `"package "` or `""`, matching the enum's declared access level.
  var accessModifierPrefix: String {
    for modifier in modifiers {
      switch modifier.name.tokenKind {
      case .keyword(.public): return "public "
      case .keyword(.package): return "package "
      default: continue
      }
    }
    return ""
  }

  /// The case declarations written directly in the enum body, in source order.
  var caseDecls: [EnumCaseDeclSyntax] {
    memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
  }

  /// Whether the enum body declares a non-static `var` whose identifier is `propertyName`.
  func declaresInstanceProperty(named propertyName: String) -> Bool {
    memberBlock.members.contains { member in
      guard let variable = member.decl.as(VariableDeclSyntax.self),
            !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) else { return false }
      return variable.bindings.contains {
        $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == propertyName
      }
    }
  }

  /// Whether the enum carries an attribute called `name`, written bare (`@Name`) or
  /// module-qualified (`@Module.Name`).
  func hasAttribute(named name: String) -> Bool {
    attributes.contains { element in
      guard let attribute = element.as(AttributeSyntax.self) else { return false }
      if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
        return identifier.name.text == name
      }
      if let member = attribute.attributeName.as(MemberTypeSyntax.self) {
        return member.name.text == name
      }
      return false
    }
  }
}

extension EnumCaseDeclSyntax {
  /// The attributes whose name is in `names`, in source order. Matches bare (`@Name`) and
  /// module-qualified (`@Module.Name`) spellings; the returned name is always the bare one.
  func markerAttributes(named names: Set<String>) -> [(name: String, attribute: AttributeSyntax)] {
    attributes.compactMap { element in
      guard let attribute = element.as(AttributeSyntax.self) else { return nil }
      let name: String
      if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
        name = identifier.name.text
      } else if let member = attribute.attributeName.as(MemberTypeSyntax.self) {
        name = member.name.text
      } else {
        return nil
      }
      guard names.contains(name) else { return nil }
      return (name, attribute)
    }
  }
}

extension EnumCaseElementSyntax {
  /// A pattern matching the element regardless of its payload: `.a` or `.a(_, _)`.
  var wildcardPattern: String {
    let paramCount = parameterClause?.parameters.count ?? 0
    return paramCount == 0
      ? ".\(name.text)"
      : ".\(name.text)(\(Array(repeating: "_", count: paramCount).joined(separator: ", ")))"
  }
}
