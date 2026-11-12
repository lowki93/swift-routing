# DocC Article Rules (SwiftRouting)

This file defines how DocC articles in `Sources/SwiftRouting/SwiftRouting.docc/` are organized, placed, linked and verified. Syntax questions (directives, symbol links, formatting) are covered by the `swift-docc` skill; this file covers organization.

## 1. Reading order

- The reference order is the Topics order in `SwiftRouting.md`, mirrored by the Next Steps of `GettingStarted.md`.
- An article never introduces a concept the reader hasn't met at that position. When unavoidable, name it with an explicit link ("see `<doc:X>`") without explaining it.

## 2. One home per feature

- The detailed rules of a feature (tables, compile-time errors, limits) live in a single article.
- Other articles keep a short example and a link. Why: duplicated rules drift apart.

## 3. Symmetry

- Comparable features get the same treatment (both a dedicated article, or both a section).
- An asymmetry must be a deliberate choice, not a leftover of history.

## 4. Opt-in products

- Opt-in products (macros, test support) get their own Topics group, placed after every concept they extend.

## 5. Navigation

- Every article appears in a Topics group of `SwiftRouting.md` and in the Next Steps of `GettingStarted.md`, in the same order. `scripts/check-getting-started-links.py` checks that every Topics article is linked from Next Steps; keep the order consistent by hand.
- A user-facing article also gets a row in the README Documentation table. Its link points to the current release version (`.github/workflows/changelog.yml` bumps it at each release).

## 6. Titles and structure

- Title: a short noun phrase in the style of "Tab Navigation", "Deep Linking", "Macros". No API names.
- One-sentence abstract saying what the reader can do.
- Structure: `## Overview`, then the sections, then `## Topics` with `### Related`.

## 7. Accuracy

- Every documented behavior is covered by a test.
- Every example matches the real code (same case names, same results).
- Never document a limit that is no longer true.
- Read the code before writing a rule.

## 8. Links

- Articles: `<doc:Article>`. Headings: `<doc:Article#Heading>`; DocC drops punctuation such as `@` from the anchor (`#Tab-Routes`, `#Generating-Tabs-with-TabRoutable`).
- The `SwiftRouting` catalog can't link symbols of another module (such as the macros): write them in plain backticks.
- Docstrings in `SwiftRoutingMacros` use ``` ``Symbol`` ``` links.

## 9. Renaming

- Renaming an article (hence its URL) is only allowed if it was never published in a release. Otherwise keep the file name.

## 10. CHANGELOG

- Under `[Unreleased]`, entries describe the final state of the docs, not intermediate moves or renames.

## 11. Style

- Code in articles is indented with 4 spaces.
- Use `> Tip:` / `> Note:` for short pointers.

## 12. Verification

```bash
swift package generate-documentation --target SwiftRouting --warnings-as-errors
python3 scripts/check-getting-started-links.py
python3 scripts/check-benefits-table-sync.py
```

If a running `preview-documentation` locks `.build`, add `--scratch-path /tmp/swr-build` to the first command.
