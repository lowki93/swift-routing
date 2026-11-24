#!/usr/bin/env python3
"""Aggregate agent quality signals from GitHub PRs.

Two sections:
- Linear flow: the "**Agent metrics**:" block of merged PR bodies, plus human
  fixup commits (commits without a "Co-Authored-By: Claude" trailer).
- CI review: threads posted by the Claude review bot, with reactions,
  "Fixed in" replies, probable noise and missed problems.

See ai-rules/agent_metrics.md.

Usage:
  python3 scripts/agent-metrics.py [--since YYYY-MM-DD] [--json] [--repo OWNER/NAME]
  python3 scripts/agent-metrics.py --self-test
"""

import argparse
import json
import re
import subprocess
import sys
from datetime import date, timedelta

LINEAR_TITLE = re.compile(r"\[SWI-\d+\]")
SECTION_HEADER = re.compile(r"^\*\*Agent metrics\*\*\s*:", re.IGNORECASE)
OTHER_HEADER = re.compile(r"^\*\*[^*]+\*\*\s*:")
AGENT_LINE = re.compile(r"^\s*[-*]\s*(plan|dev|reviewer)\s*:\s*(.*)$", re.IGNORECASE)
CLAUDE_TRAILER = re.compile(r"^\s*Co-Authored-By:\s*Claude", re.IGNORECASE | re.MULTILINE)
CHANGE_CATEGORIES = {"scope", "api", "naming", "docs", "tests", "structure", "other", "none"}
PR_LIMIT = 200
THREAD_LIMIT = 100
COMMENT_LIMIT = 50
INT_KEYS = {
    "plan": {"rounds"},
    "dev": {"test_failures"},
    "reviewer": {"blocking", "should_fix", "nit", "fixed", "skipped"},
}


# ---------------------------------------------------------------- pure parsing


def parse_agent_metrics(body):
    """Parse the Agent metrics section of a PR body. None if absent."""
    if not body:
        return None
    lines = body.replace("\r\n", "\n").split("\n")
    start = next((i for i, l in enumerate(lines) if SECTION_HEADER.match(l.strip())), None)
    if start is None:
        return None
    result = {}
    for line in lines[start + 1 :]:
        if OTHER_HEADER.match(line.strip()):
            break
        m = AGENT_LINE.match(line)
        if not m:
            continue
        agent, rest = m.group(1).lower(), m.group(2)
        values = result.setdefault(agent, {})
        for pair in rest.split(";"):
            if "=" not in pair:
                continue
            key, value = (s.strip() for s in pair.split("=", 1))
            key = key.lower()
            if key in INT_KEYS[agent]:
                if re.fullmatch(r"\d+", value):
                    values[key] = int(value)
            elif agent == "dev" and key == "stopped":
                if value.lower() in ("yes", "no"):
                    values[key] = value.lower() == "yes"
            elif agent == "plan" and key == "changes":
                items = [c.strip().lower() for c in value.split(",") if c.strip()]
                items = [c if c in CHANGE_CATEGORIES else "other" for c in items]
                values[key] = [c for c in items if c != "none"]
    return result


def is_claude_commit(message_body):
    return bool(CLAUDE_TRAILER.search(message_body or ""))


def is_merge_commit(commit):
    return (commit.get("messageHeadline") or "").startswith("Merge ")


def human_fixups(commits):
    """Non-merge commits without a Claude co-author trailer."""
    return [
        c for c in commits
        if not is_merge_commit(c) and not is_claude_commit(c.get("messageBody"))
    ]


def is_linear_flow_pr(pr):
    return bool(LINEAR_TITLE.search(pr.get("title") or ""))


# ------------------------------------------------------------ pure aggregation


def _avg(values):
    return sum(values) / len(values) if values else None


def aggregate_linear(prs):
    flow = [p for p in prs if is_linear_flow_pr(p)]
    parsed = [(p, parse_agent_metrics(p.get("body"))) for p in flow]
    with_metrics = [m for _, m in parsed if m]
    missing = [{"number": p["number"], "title": p["title"]} for p, m in parsed if not m]

    rounds = [m["plan"]["rounds"] for m in with_metrics if "rounds" in m.get("plan", {})]
    changes = {}
    for m in with_metrics:
        for c in m.get("plan", {}).get("changes", []):
            changes[c] = changes.get(c, 0) + 1
    failures = [m["dev"]["test_failures"] for m in with_metrics if "test_failures" in m.get("dev", {})]
    stopped = [m["dev"]["stopped"] for m in with_metrics if "stopped" in m.get("dev", {})]
    reviewer = {k: 0 for k in INT_KEYS["reviewer"]}
    for m in with_metrics:
        for k, v in m.get("reviewer", {}).items():
            reviewer[k] += v
    decided = reviewer["fixed"] + reviewer["skipped"]

    fixup_prs = []
    total_fixups = 0
    agent_prs = [p for p in prs if any(is_claude_commit(c.get("messageBody")) for c in p.get("commits") or [])]
    for p in agent_prs:
        fixups = human_fixups(p.get("commits") or [])
        if fixups:
            total_fixups += len(fixups)
            fixup_prs.append({
                "number": p["number"], "title": p["title"],
                "human_commits": len(fixups),
                "commits": len(p.get("commits") or []),
                "linear_flow": is_linear_flow_pr(p),
            })

    return {
        "merged_prs": len(prs),
        "linear_flow_prs": len(flow),
        "prs_with_metrics": len(with_metrics),
        "missing_section": missing,
        "plan": {
            "avg_rounds": _avg(rounds),
            "first_round_pct": (100 * sum(1 for r in rounds if r == 1) / len(rounds)) if rounds else None,
            "changes": changes,
        },
        "dev": {
            "avg_test_failures": _avg(failures),
            "stopped_pct": (100 * sum(stopped) / len(stopped)) if stopped else None,
        },
        "reviewer": {**reviewer, "fix_rate_pct": (100 * reviewer["fixed"] / decided) if decided else None},
        "human_fixups": {
            "agent_written_prs": len(agent_prs),
            "prs_with_fixups": len(fixup_prs),
            "total_commits": total_fixups,
            "prs": fixup_prs,
        },
    }


def is_bot_author(author):
    return bool(author) and author.get("__typename") == "Bot" and author.get("login") == "claude"


def _reaction(comment, content, pr_author):
    """Count a reaction, ignoring the PR author and reactors without a user (bots)."""
    nodes = (comment.get("reactions") or {}).get("nodes") or []
    return sum(
        1 for n in nodes
        if n.get("content") == content
        and (n.get("user") or {}).get("login")
        and n["user"]["login"] != pr_author
    )


def classify_bot_thread(thread, pr_author=None):
    """Classify one thread started by the bot (None if not a bot thread)."""
    comments = (thread.get("comments") or {}).get("nodes") or []
    if not comments or not is_bot_author(comments[0].get("author")):
        return None
    first = comments[0]
    up = _reaction(first, "THUMBS_UP", pr_author)
    down = _reaction(first, "THUMBS_DOWN", pr_author)
    fixed = any((c.get("body") or "").startswith("Fixed in ") for c in comments[1:])
    noise = down > 0 or (bool(thread.get("isResolved")) and not fixed)
    return {"up": up, "down": down, "fixed": fixed, "noise": noise}


def aggregate_threads(threads, pr_author=None):
    """Aggregate the review threads of one PR."""
    findings = up = down = fixed = noise = 0
    bot_times = []
    for t in threads:
        c = classify_bot_thread(t, pr_author)
        if c is None:
            continue
        findings += 1
        up += c["up"]
        down += c["down"]
        fixed += c["fixed"]
        noise += c["noise"]
        created = t["comments"]["nodes"][0].get("createdAt")
        if created:
            bot_times.append(created)
    human_after = 0
    if bot_times:
        earliest = min(bot_times)
        for t in threads:
            nodes = (t.get("comments") or {}).get("nodes") or []
            if not nodes:
                continue
            author = nodes[0].get("author") or {}
            if author.get("__typename") == "User" and author.get("login") != pr_author \
                    and nodes[0].get("createdAt") and nodes[0]["createdAt"] > earliest:
                human_after += 1
    return {"findings": findings, "up": up, "down": down, "fixed": fixed,
            "noise": noise, "human_threads_after_review": human_after}


def precision(agg):
    """(percent, basis) or (None, None)."""
    votes = agg["up"] + agg["down"]
    if votes:
        return 100 * agg["up"] / votes, "votes"
    if agg["findings"]:
        return 100 * agg["fixed"] / agg["findings"], "fixed/findings"
    return None, None


def aggregate_ci(per_pr):
    total = {k: sum(p[k] for p in per_pr) for k in ("findings", "up", "down", "fixed", "noise", "human_threads_after_review")}
    pct, basis = precision(total)
    return {"prs": per_pr, "total": total, "precision_pct": pct, "precision_basis": basis}


# ------------------------------------------------------------------- gh layer


def gh(*args):
    try:
        out = subprocess.run(["gh", *args], capture_output=True, text=True, check=True)
    except FileNotFoundError:
        print("error: the `gh` CLI is not installed", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"error: `gh {' '.join(args[:2])}` failed: {e.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
    return out.stdout


def detect_repo():
    return json.loads(gh("repo", "view", "--json", "nameWithOwner"))["nameWithOwner"]


def warn(message):
    print(f"warning: {message}", file=sys.stderr)


def fetch_merged_prs(repo, since):
    out = gh("pr", "list", "--repo", repo, "--state", "merged", "--search", f"merged:>={since}",
             "--limit", str(PR_LIMIT), "--json", "number,title,body,mergedAt,url")
    prs = json.loads(out)
    if len(prs) >= PR_LIMIT:
        warn(f"merged PR list hit the limit of {PR_LIMIT}: results may be truncated")
    # Commits are fetched per PR: asking for them in the list query exceeds
    # GitHub's GraphQL node limit.
    for pr in prs:
        view = gh("pr", "view", str(pr["number"]), "--repo", repo, "--json", "commits")
        pr["commits"] = json.loads(view)["commits"]
    return prs


def fetch_updated_prs(repo, since):
    out = gh("pr", "list", "--repo", repo, "--state", "all", "--search", f"updated:>={since}",
             "--limit", str(PR_LIMIT), "--json", "number,title,author")
    prs = json.loads(out)
    if len(prs) >= PR_LIMIT:
        warn(f"updated PR list hit the limit of {PR_LIMIT}: results may be truncated")
    return prs


THREADS_QUERY = """
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved
          comments(first: 50) {
            nodes {
              author { __typename login }
              createdAt body
              reactions(first: 50) { nodes { content user { login } } }
            }
          }
        }
      }
    }
  }
}
"""


def fetch_threads(owner, name, number):
    out = gh("api", "graphql", "-f", f"query={THREADS_QUERY}", "-F", f"owner={owner}",
             "-F", f"name={name}", "-F", f"number={number}")
    pr = json.loads(out)["data"]["repository"]["pullRequest"]
    threads = pr["reviewThreads"]["nodes"]
    if len(threads) >= THREAD_LIMIT:
        warn(f"PR #{number} hit the limit of {THREAD_LIMIT} review threads: results may be truncated")
    if any(len((th.get("comments") or {}).get("nodes") or []) >= COMMENT_LIMIT for th in threads):
        warn(f"PR #{number} has a thread with {COMMENT_LIMIT}+ comments: results may be truncated")
    return threads


def collect_ci(repo, since):
    owner, name = repo.split("/", 1)
    per_pr = []
    for pr in fetch_updated_prs(repo, since):
        author = (pr.get("author") or {}).get("login")
        agg = aggregate_threads(fetch_threads(owner, name, pr["number"]), author)
        if agg["findings"]:
            per_pr.append({"number": pr["number"], "title": pr["title"], **agg})
    return aggregate_ci(per_pr)


# ------------------------------------------------------------------- rendering


def cell(text):
    return str(text).replace("|", "\\|")


def fmt(value, suffix="", digits=1):
    if value is None:
        return "n/a"
    return f"{value:.{digits}f}{suffix}"


def render_markdown(since, linear, ci):
    out = [f"# Agent metrics (since {since})", "", "## Linear flow", ""]
    if not linear["merged_prs"]:
        out += ["No merged PRs in this period.", ""]
    else:
        out += [
            f"PRs with metrics: {linear['prs_with_metrics']} / {linear['linear_flow_prs']} Linear-flow PRs"
            f" ({linear['merged_prs']} merged PRs in total).", "",
        ]
        p, d, r = linear["plan"], linear["dev"], linear["reviewer"]
        out += [
            "| Agent | Metric | Value |", "|---|---|---|",
            f"| plan | average rounds | {fmt(p['avg_rounds'])} |",
            f"| plan | approved on first round | {fmt(p['first_round_pct'], '%', 0)} |",
            f"| plan | changes | {', '.join(f'{k}: {v}' for k, v in sorted(p['changes'].items())) or 'none'} |",
            f"| dev | average test failures | {fmt(d['avg_test_failures'])} |",
            f"| dev | stopped to ask | {fmt(d['stopped_pct'], '%', 0)} |",
            f"| reviewer | blocking / should_fix / nit | {r['blocking']} / {r['should_fix']} / {r['nit']} |",
            f"| reviewer | fixed / skipped | {r['fixed']} / {r['skipped']} |",
            f"| reviewer | fix rate | {fmt(r['fix_rate_pct'], '%', 0)} |",
            "",
        ]
        h = linear["human_fixups"]
        out += [f"Human fixups (agent-written PRs only): {h['prs_with_fixups']} of {h['agent_written_prs']} "
                f"PR(s) have at least one human commit, {h['total_commits']} commit(s) in total.", ""]
        if h["prs"]:
            out += ["| PR | Linear flow | Human commits | Commits |", "|---|---|---|---|"]
            out += [f"| #{x['number']} {cell(x['title'])} | {'yes' if x['linear_flow'] else 'no'} | "
                    f"{x['human_commits']} | {x['commits']} |" for x in h["prs"]]
            out.append("")
        out.append("Linear-flow PRs missing the Agent metrics section:")
        out += [f"- #{x['number']} {x['title']}" for x in linear["missing_section"]] or ["- none"]
        out.append("")

    out += ["## CI review", ""]
    if not ci["prs"]:
        out += ["No PR with Claude review threads in this period.", ""]
    else:
        out += ["| PR | Findings | 👍 | 👎 | Fixed | Probable noise | Human threads after review |", "|---|---|---|---|---|---|---|"]
        for x in ci["prs"]:
            out.append(f"| #{x['number']} {cell(x['title'])} | {x['findings']} | {x['up']} | {x['down']} | "
                       f"{x['fixed']} | {x['noise']} | {x['human_threads_after_review']} |")
        t = ci["total"]
        out.append(f"| **Total** | {t['findings']} | {t['up']} | {t['down']} | {t['fixed']} | {t['noise']} | {t['human_threads_after_review']} |")
        out += ["", f"Precision: {fmt(ci['precision_pct'], '%', 0)} (basis: {ci['precision_basis'] or 'n/a'})", ""]

    out += [
        "## How to read", "",
        "- Plans approved on the first round most of the time (for example above 80%) for a ticket type: "
        "the plan gate can be lighter for that type.",
        "- Low CI precision, or high probable noise: tighten the `pull-request-review` skill.",
        "- Human threads after review may include problems the bot missed: read them. Many human fixups mean the agents need more control there, not more autonomy.",
    ]
    return "\n".join(out)


# ------------------------------------------------------------------ self-test


def check(condition, message="self-test failed"):
    if not condition:
        raise SystemExit(f"self-test failed: {message}")


def self_test():
    full = ("**What**:\nx\n\n**Agent metrics**: extra text\n- plan: rounds=2; changes=scope,api\n"
            "- dev: test_failures=1; stopped=no\n"
            "- reviewer: blocking=0; should_fix=3; nit=2; fixed=4; skipped=1\n\n**Review notes**:\nfoo rounds=9\n")
    check(parse_agent_metrics(full) == {
        "plan": {"rounds": 2, "changes": ["scope", "api"]},
        "dev": {"test_failures": 1, "stopped": False},
        "reviewer": {"blocking": 0, "should_fix": 3, "nit": 2, "fixed": 4, "skipped": 1},
    }, "complete section")
    partial = "**Agent metrics**:\n-  plan:  rounds = 1 ;  changes=none\n- dev: stopped=yes"
    check(parse_agent_metrics(partial) == {"plan": {"rounds": 1, "changes": []}, "dev": {"stopped": True}},
          "partial section")
    check(parse_agent_metrics("**Agent metrics**:\n- plan: rounds=-1; changes=weird,docs") ==
          {"plan": {"changes": ["other", "docs"]}}, "negative ints and unknown changes")
    check(parse_agent_metrics("**What**:\nnothing") is None, "absent section")
    check(parse_agent_metrics(None) is None, "no body")

    claude = "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
    check(is_claude_commit(f"msg\n\n{claude}"), "claude trailer")
    check(not is_claude_commit("msg\n\nCo-Authored-By: Someone <a@b.c>"), "other trailer")
    commits = [
        {"messageHeadline": "add x", "messageBody": claude},
        {"messageHeadline": "fix typo", "messageBody": ""},
        {"messageHeadline": "Merge branch 'main' into x", "messageBody": ""},
    ]
    check([c["messageHeadline"] for c in human_fixups(commits)] == ["fix typo"], "human fixups")
    linear = aggregate_linear([
        {"number": 1, "title": "feat: [SWI-1] a", "body": "", "commits": commits},
        {"number": 2, "title": "fix: human only", "body": "", "commits": [commits[1]]},
    ])
    check(linear["human_fixups"]["agent_written_prs"] == 1 and linear["human_fixups"]["total_commits"] == 1,
          "fixups only on agent-written PRs")
    check(is_linear_flow_pr({"title": "feat: [SWI-5] x"}) and not is_linear_flow_pr({"title": "fix: x"}),
          "linear flow title")

    bot = {"__typename": "Bot", "login": "claude"}
    user = {"__typename": "User", "login": "bob"}
    owner = {"__typename": "User", "login": "alice"}

    def vote(content, login):
        return {"content": content, "user": {"login": login} if login else None}

    def thread(author, created, resolved=False, reactions=(), replies=()):
        nodes = [{"author": author, "createdAt": created, "body": "b", "reactions": {"nodes": list(reactions)}}]
        nodes += [{"author": {"__typename": "Bot", "login": "github-actions"}, "createdAt": created, "body": r,
                   "reactions": {"nodes": []}} for r in replies]
        return {"id": "t", "isResolved": resolved, "comments": {"nodes": nodes}}

    check(classify_bot_thread(thread(user, "2026-01-01")) is None, "human thread is not a bot thread")
    check(classify_bot_thread(thread(bot, "2026-01-01", True, replies=["Fixed in abc"])) ==
          {"up": 0, "down": 0, "fixed": True, "noise": False}, "fixed thread")
    check(classify_bot_thread(thread(bot, "2026-01-01", True))["noise"], "resolved without fix is noise")
    check(classify_bot_thread(thread(bot, "2026-01-01", False, [vote("THUMBS_DOWN", "bob")]))["noise"],
          "thumbs down is noise")
    ignored = classify_bot_thread(
        thread(bot, "2026-01-01", False, [vote("THUMBS_UP", "alice"), vote("THUMBS_UP", None)]), "alice")
    check(ignored["up"] == 0, "votes from the PR author and bots are ignored")
    agg = aggregate_threads([
        thread(bot, "2026-01-02", reactions=[vote("THUMBS_UP", "bob")]),
        thread(bot, "2026-01-03", True, replies=["Fixed in abc"]),
        thread(user, "2026-01-01"),
        thread(user, "2026-01-05"),
        thread(owner, "2026-01-06"),
    ], "alice")
    check(agg == {"findings": 2, "up": 1, "down": 0, "fixed": 1, "noise": 0, "human_threads_after_review": 1},
          repr(agg))
    check(aggregate_threads([thread(bot, ""), thread(user, "2026-01-05")])["human_threads_after_review"] == 0,
          "no valid bot timestamp")
    check(precision(agg) == (100.0, "votes"), "precision from votes")
    check(precision({"up": 0, "down": 0, "fixed": 1, "findings": 2}) == (50.0, "fixed/findings"),
          "precision fallback")
    print("OK")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--since", help="YYYY-MM-DD (default: 30 days ago)")
    ap.add_argument("--json", action="store_true", help="print raw aggregates as JSON")
    ap.add_argument("--repo", help="OWNER/NAME (default: current repository)")
    ap.add_argument("--self-test", action="store_true", help="run built-in assertions and exit")
    args = ap.parse_args()
    if args.self_test:
        self_test()
        return 0
    try:
        since = date.fromisoformat(args.since) if args.since else date.today() - timedelta(days=30)
    except ValueError:
        print("error: --since must be a valid date in YYYY-MM-DD format", file=sys.stderr)
        return 1
    since = since.isoformat()
    repo = args.repo or detect_repo()
    linear = aggregate_linear(fetch_merged_prs(repo, since))
    ci = collect_ci(repo, since)
    if args.json:
        print(json.dumps({"since": since, "repo": repo, "linear_flow": linear, "ci_review": ci}, indent=2))
    else:
        print(render_markdown(since, linear, ci))
    return 0


if __name__ == "__main__":
    sys.exit(main())
