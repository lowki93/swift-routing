# Medium Article Rules (SwiftRouting)

This file defines how to draft the swift-routing Medium articles (`medium-articles/`, Linear label `Article`). The rules come from what the author consistently changed between Claude's drafts and the published versions (articles 01–05). Follow them so the first draft needs fewer edits. The author always reviews before publishing.

## Scope

1. **One feature per article.** Deep linking, testing, macros and other features get their own article unless they are the subject.
2. **No teasers.** Never write "coming up later in this series" or announce future articles. Cut a deferred topic entirely, without a placeholder line.

## Structure

3. **Title** names the API exactly as it is spelled in code (`SplitView`, `TabRouter`, `RouteContext`).
4. **Series line** (first line, italics). It links every earlier part by its full Medium title, without summarizing them:

   ```markdown
   *Part N of the swift-routing series. If you're new here, start with [Part 1: <full title>](<url>), [Part 2: <full title>](<url>), and [Part N-1: <full title>](<url>)*
   ```

   Copy the titles and URLs from the previous article's series line.
5. **Section order:**
   1. The problem, shown with vanilla SwiftUI code.
   2. One section per API feature.
   3. "Before and After".
   4. "Why This Matters" or "But What About X?".
6. **Last line**, exactly:

   ```markdown
   The library is open source — explore the code, open issues, or contribute: [github.com/lowki93/swift-routing](https://github.com/lowki93/swift-routing)
   ```
7. **Length:** 1250–1450 words. Every published article falls in this range.

## Tone

8. **Short sentences.** Average 15 words or fewer, none over 35. The articles the author shaped most average 14 words; long drafts averaged 26–35.
9. **Opinionated and direct.** Address the reader as "you". Use "I" only for the author's real experience.
10. **No competitors, no history detours.** Don't name other libraries or their authors. Don't digress into UIKit history or dates.
11. **No empty intensifiers** ("exact", "exactly the same", "entirely") unless they carry meaning.
12. **No niche jargon or wordplay** that could read as a typo (for example "stringly-typed").
13. **Never invent personal facts** (durations, company details, numbers). Write `[TODO: confirm]` and let the author fill them in.

## Code

14. **Everything is declared.** Every route, type or module used in prose or code is declared in a block shown earlier in the same article. No placeholder names (`RoutingKit`, `AppShell`).
15. **Every block compiles as written:**
    - balanced, correctly indented braces;
    - current API names, checked against `Sources/` (`pop()`, not `back()`);
    - the current version from `README.md` / `Package.swift`;
    - prefer types and flows from `Examples/SwiftRoutingDemo`.
16. **Realistic examples.**
    - Before/After examples use a plain in-app trigger, such as a button or a confirmation sheet.
    - The code lives in a named type or view, never in a free-floating function.
17. **Tests:** separate arrange, act and assert with blank lines.
18. **Comments** go on their own line above the code they describe, not at the end of a line.

## Formatting (Medium)

19. **Em dash** `—`, never `--`.
20. **Punctuation outside inline code:** `` `selection`: ``, not `` `selection:` ``.
21. **Bold** only for one key concept per section, not for labels or the thesis sentence.
22. **"Swift-routing"** is capitalized at the start of a sentence. Write `swift-routing` everywhere else.

## Before Handing Over a Draft

23. **Self-check** the draft against this file and report the results with it:
    - word count;
    - average and longest sentence length;
    - every name declared;
    - API names checked against `Sources/`;
    - series line;
    - last line.

## Lessons From the Last Edit

24. **Keep this file current.** After each published article, compare the draft with the published version (`git diff` on `medium-articles/`). Add any new recurring correction as a rule above.
