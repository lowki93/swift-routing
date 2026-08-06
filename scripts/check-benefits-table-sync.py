#!/usr/bin/env python3
"""Fail if the "Why SwiftRouting?" benefits table in README.md and
SwiftRouting.md have drifted apart.

README.md uses single backticks for symbol references; SwiftRouting.md (a
DocC catalog page) uses double backticks so DocC can link resolvable
symbols. That's the only expected difference -- everything else (rows,
wording) must match exactly.

Usage: python3 scripts/check-benefits-table-sync.py
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
README = REPO_ROOT / "README.md"
DOCC_LANDING_PAGE = REPO_ROOT / "Sources/SwiftRouting/SwiftRouting.docc/SwiftRouting.md"

TABLE_HEADER = "| Benefit | Description |"


def extract_table(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    start = text.find(TABLE_HEADER)
    if start == -1:
        print(f"error: could not find '{TABLE_HEADER}' in {path}", file=sys.stderr)
        sys.exit(1)
    end = text.find("\n\n", start)
    block = text[start : end if end != -1 else len(text)]
    return [line for line in block.splitlines() if line.startswith("|")]


def normalize(line: str) -> str:
    # DocC catalog pages use double backticks for linkable symbols; README
    # uses single backticks. That's the only allowed difference.
    return re.sub(r"``([^`]+)``", r"`\1`", line)


def main() -> int:
    readme_rows = [normalize(line) for line in extract_table(README)]
    docc_rows = [normalize(line) for line in extract_table(DOCC_LANDING_PAGE)]

    if readme_rows == docc_rows:
        print("OK: benefits tables are in sync.")
        return 0

    print("error: README.md and SwiftRouting.md benefits tables have drifted apart.")
    print(f"  {README.relative_to(REPO_ROOT)}: {len(readme_rows)} rows")
    print(f"  {DOCC_LANDING_PAGE.relative_to(REPO_ROOT)}: {len(docc_rows)} rows")
    print()
    print("Diff (after normalizing `` -> ` for comparison):")
    import difflib

    diff = difflib.unified_diff(
        docc_rows,
        readme_rows,
        fromfile=str(DOCC_LANDING_PAGE.relative_to(REPO_ROOT)),
        tofile=str(README.relative_to(REPO_ROOT)),
        lineterm="",
    )
    print("\n".join(diff))
    return 1


if __name__ == "__main__":
    sys.exit(main())
