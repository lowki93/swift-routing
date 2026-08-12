#!/usr/bin/env python3
"""Fail if GettingStarted.md's "Next Steps" section doesn't link every
article listed in SwiftRouting.md's "## Topics" section.

Someone landing on the first page of the docs should have a path to every
other article without already knowing the landing page's Topics section
exists -- see SWI-43.

Usage: python3 scripts/check-getting-started-links.py
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCC_LANDING_PAGE = REPO_ROOT / "Sources/SwiftRouting/SwiftRouting.docc/SwiftRouting.md"
GETTING_STARTED = REPO_ROOT / "Sources/SwiftRouting/SwiftRouting.docc/GettingStarted.md"

DOC_LINK = re.compile(r"<doc:(\w+)>")


def extract_section(path: Path, header: str) -> str:
    text = path.read_text(encoding="utf-8")
    start = text.find(header)
    if start == -1:
        print(f"error: could not find '{header}' in {path}", file=sys.stderr)
        sys.exit(1)
    next_heading = text.find("\n## ", start + len(header))
    return text[start : next_heading if next_heading != -1 else len(text)]


def main() -> int:
    topics = extract_section(DOCC_LANDING_PAGE, "## Topics")
    next_steps = extract_section(GETTING_STARTED, "## Next Steps")

    # GettingStarted itself is the page the reader is already on -- Next
    # Steps pointing back to it would be redundant, not a missing link.
    topic_articles = set(DOC_LINK.findall(topics)) - {"GettingStarted"}
    next_steps_articles = set(DOC_LINK.findall(next_steps))

    missing = topic_articles - next_steps_articles
    extra = next_steps_articles - topic_articles

    if not missing and not extra:
        print("OK: Getting Started's Next Steps links every article in the Topics section.")
        return 0

    print("error: GettingStarted.md's Next Steps section has drifted from SwiftRouting.md's Topics section.")
    if missing:
        print(f"  Missing from Next Steps: {', '.join(sorted(missing))}")
    if extra:
        print(f"  In Next Steps but not in Topics (renamed/removed article?): {', '.join(sorted(extra))}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
