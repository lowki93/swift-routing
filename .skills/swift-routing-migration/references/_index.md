# SwiftRouting Migration References

Follow this order for a complete migration:

1. `routes.md`: Define route enums, map them to views, replace `NavigationStack`.
2. `navigation.md`: Replace push, sheet, cover, and dismiss navigation calls.
3. `deeplinks.md`: Replace manual `NavigationPath` mutation with `DeeplinkHandler`.
