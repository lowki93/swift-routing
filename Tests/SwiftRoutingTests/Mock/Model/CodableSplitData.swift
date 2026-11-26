/// A `Codable` content selection of a split, used by the navigation restoration tests.
enum CodableSplitContent: String, Codable, Hashable, Sendable {
  case players
  case teams
}

/// A `Codable` detail selection of a split, used by the navigation restoration tests.
struct CodableSplitDetail: Codable, Hashable, Sendable {
  let id: String
}

/// A detail selection that is not `Codable`.
struct NonCodableSplitDetail: Hashable, Sendable {
  let id: String
}

/// A content selection that is not `Codable`.
struct NonCodableSplitContent: Hashable, Sendable {
  let id: String
}
