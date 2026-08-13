# Swift Code Conventions (SwiftRouting)

This file defines the Swift code conventions for the project.

- **Naming**: PascalCase for types, lowerCamelCase for properties/methods/enum cases
- **Access control**: `public` only for exposed APIs, `private`/`internal` by default
- **Concurrency**: `@MainActor` on main types, `@unchecked Sendable` for thread-safe classes
- **Public classes**: `public final class`
- **Doc comments**: `///` with Swift code examples on all public types and methods
