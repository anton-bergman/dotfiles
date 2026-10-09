#!/usr/bin/env python3
"""
gh_draft_review.py - GitHub Draft PR Review Staging CLI

Stages inline review comments into a PENDING review on GitHub so that an AI
agent can propose comments without publishing them. The user reviews and submits
the review manually in GitHub.

Supports:
- Single-line, multi-line ranges, and cross-side replacement comments
- Stateful reconciliation loop (add, update in-place, delete pruned, deduplicate)
Zero external dependencies - uses Python standard library and `gh` CLI.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional, Set, Tuple


class DiffHunk:
    """Represents a unified diff hunk and tracks valid line numbers for both sides."""

    def __init__(self, file_path: str, old_start: int, new_start: int):
        self.file_path = file_path
        self.old_start = old_start
        self.new_start = new_start
        self.left_lines: Set[int] = set()
        self.right_lines: Set[int] = set()

    def contains_single(self, side: str, line: int) -> bool:
        if side == "LEFT":
            return line in self.left_lines
        return line in self.right_lines

    def contains_range(
        self, start_side: str, start_line: int, end_side: str, end_line: int
    ) -> bool:
        start_ok = (
            start_line in self.left_lines
            if start_side == "LEFT"
            else start_line in self.right_lines
        )
        end_ok = (
            end_line in self.left_lines
            if end_side == "LEFT"
            else end_line in self.right_lines
        )
        if not (start_ok and end_ok):
            return False

        # Directionality check
        if start_side == end_side:
            return start_line <= end_line
        elif start_side == "LEFT" and end_side == "RIGHT":
            # Valid cross-side replacement (deleted on left, replaced on right)
            return True
        else:
            # RIGHT -> LEFT is invalid in git diffs
            return False


def get_gh_token() -> str:
    """Retrieve GitHub token from gh CLI or environment."""
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        return token.strip()
    try:
        res = subprocess.run(
            ["gh", "auth", "token"],
            capture_output=True,
            text=True,
            check=True,
        )
        return res.stdout.strip()
    except Exception as e:
        sys.stderr.write(f"Error getting GitHub token via `gh auth token`: {e}\n")
        sys.stderr.write("Please run `gh auth login` to authenticate.\n")
        sys.exit(1)


def get_authenticated_user(token: str) -> str:
    """Get the login name of the authenticated user."""
    req = urllib.request.Request(
        "https://api.github.com/user",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "gh-draft-review",
        },
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode())
        return data["login"]


def get_default_repo() -> str:
    """Get the current repository in 'owner/repo' format from git/gh."""
    try:
        res = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True,
            text=True,
            check=True,
        )
        return res.stdout.strip()
    except Exception as e:
        sys.stderr.write(f"Error determining repository: {e}\n")
        sys.stderr.write(
            "Please run inside a git repository with an associated GitHub remote, or use --repo owner/repo.\n"
        )
        sys.exit(1)


def get_default_pr() -> int:
    """Get the active PR number for the current branch."""
    try:
        res = subprocess.run(
            ["gh", "pr", "view", "--json", "number", "-q", ".number"],
            capture_output=True,
            text=True,
            check=True,
        )
        val = res.stdout.strip()
        if not val:
            raise ValueError("No PR found for current branch.")
        return int(val)
    except Exception as e:
        sys.stderr.write(f"Error determining current PR: {e}\n")
        sys.stderr.write("Please provide the PR number explicitly as an argument.\n")
        sys.exit(1)


def get_pr_details(owner_repo: str, pr_number: int, token: str) -> Dict[str, Any]:
    """Fetch PR metadata including head commit SHA."""
    url = f"https://api.github.com/repos/{owner_repo}/pulls/{pr_number}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "User-Agent": "gh-draft-review",
        },
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode())


def get_pr_diff(owner_repo: str, pr_number: int) -> str:
    """Get the unified diff for the PR via gh CLI."""
    res = subprocess.run(
        ["gh", "pr", "diff", str(pr_number), "--repo", owner_repo],
        capture_output=True,
        text=True,
        check=True,
    )
    return res.stdout


def parse_diff_hunks(diff_text: str) -> List[DiffHunk]:
    """Parse unified diff text into a list of structured DiffHunk objects."""
    hunks: List[DiffHunk] = []
    current_file: Optional[str] = None
    current_hunk: Optional[DiffHunk] = None
    cur_old = 0
    cur_new = 0

    file_header_re = re.compile(r"^\+\+\+\s+b/(.*)$")
    hunk_header_re = re.compile(r"^@@\s+-(\d+)(?:,(\d+))?\s+\+(\d+)(?:,(\d+))?\s+@@")

    for raw_line in diff_text.splitlines():
        if raw_line.startswith("+++ "):
            m = file_header_re.match(raw_line)
            if m:
                current_file = m.group(1)
                current_hunk = None
            continue
        elif raw_line.startswith("--- "):
            continue

        if not current_file:
            continue

        m_hunk = hunk_header_re.match(raw_line)
        if m_hunk:
            old_start = int(m_hunk.group(1))
            new_start = int(m_hunk.group(3))
            cur_old = old_start
            cur_new = new_start
            current_hunk = DiffHunk(current_file, old_start, new_start)
            hunks.append(current_hunk)
            continue

        if current_hunk is None:
            continue

        if raw_line.startswith("-"):
            current_hunk.left_lines.add(cur_old)
            cur_old += 1
        elif raw_line.startswith("+"):
            current_hunk.right_lines.add(cur_new)
            cur_new += 1
        elif raw_line.startswith(" "):
            current_hunk.right_lines.add(cur_new)
            current_hunk.left_lines.add(cur_old)
            cur_old += 1
            cur_new += 1

    return hunks


def api_request(
    method: str,
    endpoint: str,
    token: str,
    data: Optional[Dict[str, Any]] = None,
) -> Any:
    """Perform a GitHub REST API request with standard error handling."""
    url = f"https://api.github.com{endpoint}"
    payload = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(
        url,
        data=payload,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "User-Agent": "gh-draft-review",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            if resp.status == 204:
                return None
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode()
        try:
            err_json = json.loads(error_msg)
            message = err_json.get("message", error_msg)
            errors = err_json.get("errors", [])
            detail = f"{message}: {errors}" if errors else message
        except Exception:
            detail = error_msg
        raise RuntimeError(
            f"GitHub API error ({e.code}) on {method} {endpoint}: {detail}"
        ) from e


def graphql_request(
    query: str, variables: Dict[str, Any], token: str
) -> Dict[str, Any]:
    """Perform a GitHub GraphQL request."""
    req = urllib.request.Request(
        "https://api.github.com/graphql",
        data=json.dumps({"query": query, "variables": variables}).encode("utf-8"),
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "gh-draft-review",
        },
    )
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode())
        if "errors" in res:
            raise RuntimeError(f"GitHub GraphQL error: {res['errors']}")
        return res.get("data", {})


def find_pending_review(
    owner_repo: str, pr_number: int, current_user: str, token: str
) -> Optional[Dict[str, Any]]:
    """Find an existing PENDING review by the authenticated user."""
    endpoint = f"/repos/{owner_repo}/pulls/{pr_number}/reviews"
    reviews = api_request("GET", endpoint, token)
    for r in reviews:
        if (
            r.get("state") == "PENDING"
            and r.get("user", {}).get("login") == current_user
        ):
            return r
    return None


def get_pending_review_comments(
    review_node_id: str, token: str
) -> List[Dict[str, Any]]:
    """Fetch accurate comment line coordinates and IDs using GraphQL."""
    query = """
    query($id: ID!) {
      node(id: $id) {
        ... on PullRequestReview {
          comments(first: 100) {
            nodes {
              id
              databaseId
              path
              line
              originalLine
              startLine
              originalStartLine
              body
            }
          }
        }
      }
    }
    """
    data = graphql_request(query, {"id": review_node_id}, token)
    nodes = data.get("node", {}).get("comments", {}).get("nodes", [])
    result = []
    for c in nodes:
        result.append(
            {
                "id": c.get("databaseId"),
                "node_id": c.get("id"),
                "path": c.get("path"),
                "line": c.get("line") or c.get("originalLine"),
                "start_line": c.get("startLine") or c.get("originalStartLine"),
                "body": c.get("body", ""),
            }
        )
    return result


def cmd_status(args: argparse.Namespace, token: str) -> None:
    owner_repo = args.repo or get_default_repo()
    pr_number = args.pr or get_default_pr()
    user = get_authenticated_user(token)

    pending = find_pending_review(owner_repo, pr_number, user, token)
    if not pending:
        print(
            json.dumps(
                {"has_pending": False, "repo": owner_repo, "pr": pr_number}, indent=2
            )
        )
        return

    review_id = pending["id"]
    node_id = pending.get("node_id")
    comments = get_pending_review_comments(node_id, token) if node_id else []

    result = {
        "has_pending": True,
        "repo": owner_repo,
        "pr": pr_number,
        "review_id": review_id,
        "node_id": node_id,
        "state": pending["state"],
        "body": pending.get("body", ""),
        "comments_count": len(comments),
        "comments": comments,
    }
    print(json.dumps(result, indent=2))


def cmd_clear(args: argparse.Namespace, token: str) -> None:
    owner_repo = args.repo or get_default_repo()
    pr_number = args.pr or get_default_pr()
    user = get_authenticated_user(token)

    pending = find_pending_review(owner_repo, pr_number, user, token)
    if not pending:
        print(f"No pending review found on {owner_repo}#{pr_number} by {user}.")
        return

    review_id = pending["id"]
    api_request(
        "DELETE", f"/repos/{owner_repo}/pulls/{pr_number}/reviews/{review_id}", token
    )
    print(
        f"✓ Cleared pending review #{review_id} and all draft comments on {owner_repo}#{pr_number}."
    )


def cmd_stage(args: argparse.Namespace, token: str) -> None:
    owner_repo = args.repo or get_default_repo()
    pr_number = args.pr or get_default_pr()
    user = get_authenticated_user(token)

    # 1. Read input comments from stdin or file
    if args.input_file:
        with open(args.input_file, "r") as f:
            raw_input = json.load(f)
    else:
        if sys.stdin.isatty():
            sys.stderr.write("Error: Expected JSON comments on stdin or via --file.\n")
            sys.exit(1)
        raw_input = json.load(sys.stdin)

    add_list: List[Dict[str, Any]] = []
    update_list: List[Dict[str, Any]] = []
    remove_list: List[Dict[str, Any]] = []

    if isinstance(raw_input, dict):
        if "add" in raw_input or "update" in raw_input or "remove" in raw_input:
            add_list = raw_input.get("add", [])
            update_list = raw_input.get("update", [])
            remove_list = raw_input.get("remove", [])
        elif "comments" in raw_input:
            add_list = raw_input.get("comments", [])
        else:
            add_list = [raw_input]
    elif isinstance(raw_input, list):
        add_list = raw_input
    else:
        sys.stderr.write("Error: Invalid JSON structure provided.\n")
        sys.exit(1)

    # 2. Fetch PR details and diff
    pr_details = get_pr_details(owner_repo, pr_number, token)
    commit_id = pr_details["head"]["sha"]
    pr_url = pr_details.get(
        "html_url", f"https://github.com/{owner_repo}/pull/{pr_number}"
    )

    diff_text = get_pr_diff(owner_repo, pr_number)
    hunks = parse_diff_hunks(diff_text)

    # 3. Check for existing pending review and index existing comments
    pending = find_pending_review(owner_repo, pr_number, user, token)
    existing_comments: List[Dict[str, Any]] = []
    existing_comment_keys: Set[Tuple[str, Optional[int], int]] = set()
    existing_single_keys: Set[Tuple[str, int]] = set()
    id_to_node_id: Dict[Any, str] = {}

    if pending and pending.get("node_id"):
        existing_comments = get_pending_review_comments(pending["node_id"], token)
        for ec in existing_comments:
            db_id = ec.get("id")
            node_id_val = ec.get("node_id")
            if db_id and node_id_val:
                id_to_node_id[db_id] = node_id_val
                id_to_node_id[str(db_id)] = node_id_val
            if node_id_val:
                id_to_node_id[node_id_val] = node_id_val

            ec_path = ec.get("path")
            ec_line = ec.get("line")
            ec_start = ec.get("start_line")

            if ec_path and ec_line:
                existing_comment_keys.add((ec_path, ec_start, ec_line))
                existing_single_keys.add((ec_path, ec_line))

    # 4. Handle Deletions (remove via GraphQL)
    removed_count = 0
    if not args.dry_run and remove_list:
        delete_mutation = """
        mutation($input: DeletePullRequestReviewCommentInput!) {
          deletePullRequestReviewComment(input: $input) {
            pullRequestReviewComment {
              id
            }
          }
        }
        """
        for rem in remove_list:
            cid = rem.get("id") or rem.get("comment_id")
            target_node_id = id_to_node_id.get(cid) or (
                str(cid) if str(cid).startswith("PRRC_") else None
            )
            if target_node_id:
                try:
                    graphql_request(
                        delete_mutation, {"input": {"id": target_node_id}}, token
                    )
                    removed_count += 1
                except Exception as e:
                    sys.stderr.write(f"Notice: Failed to delete comment {cid}: {e}\n")
    else:
        removed_count = len(remove_list)

    # 5. Handle Updates (update in-place via GraphQL)
    updated_count = 0
    if not args.dry_run and update_list:
        update_mutation = """
        mutation($input: UpdatePullRequestReviewCommentInput!) {
          updatePullRequestReviewComment(input: $input) {
            pullRequestReviewComment {
              id
            }
          }
        }
        """
        for upd in update_list:
            cid = upd.get("id") or upd.get("comment_id")
            new_body = (
                upd.get("body") or upd.get("comment") or upd.get("summary") or ""
            ).strip()
            target_node_id = id_to_node_id.get(cid) or (
                str(cid) if str(cid).startswith("PRRC_") else None
            )
            if target_node_id and new_body:
                try:
                    graphql_request(
                        update_mutation,
                        {
                            "input": {
                                "pullRequestReviewCommentId": target_node_id,
                                "body": new_body,
                            }
                        },
                        token,
                    )
                    updated_count += 1
                except Exception as e:
                    sys.stderr.write(f"Notice: Failed to update comment {cid}: {e}\n")
    else:
        updated_count = len(update_list)

    # 6. Categorize Additions (Deduplication + Diff Hunk Validation)
    inline_candidates: List[Dict[str, Any]] = []
    out_of_diff_notes: List[Dict[str, Any]] = []
    skipped_dup_count = 0

    for item in add_list:
        file_path = item.get("filePath") or item.get("path") or item.get("file")
        if not file_path:
            continue

        # End line and side
        old_line = item.get("oldLine")
        new_line = item.get("newLine")
        line = item.get("line") or new_line or old_line
        if line is not None:
            line = int(line)

        side = item.get("side")
        if not side:
            side = "LEFT" if (old_line and not new_line) else "RIGHT"

        # Start line and start side (multi-line)
        start_line = item.get("startLine") or item.get("start_line")
        if start_line is not None:
            start_line = int(start_line)

        start_side = item.get("startSide") or item.get("start_side")
        if not start_side and start_line is not None:
            start_side = side

        # Normalize identical start/end to single-line
        if start_line is not None and start_line == line and start_side == side:
            start_line = None
            start_side = None

        body = item.get("body") or item.get("comment")
        if not body:
            summary = item.get("summary", "").strip()
            rationale = item.get("rationale", "").strip()
            author = item.get("author", "AI").strip()
            if summary:
                prefix = f"**[{author}]** " if author else ""
                body = f"{prefix}{summary}"
                if rationale:
                    body += f"\n\n{rationale}"

        if not body or line is None:
            continue

        # Deduplication check against existing drafts
        if (file_path, start_line, line) in existing_comment_keys or (
            start_line is None and (file_path, line) in existing_single_keys
        ):
            skipped_dup_count += 1
            continue

        # Validate range or single-line against diff hunks
        file_hunks = [h for h in hunks if h.file_path == file_path]
        is_valid_inline = False

        if start_line is not None and start_side is not None:
            for h in file_hunks:
                if h.contains_range(start_side, start_line, side, line):
                    is_valid_inline = True
                    break
        else:
            for h in file_hunks:
                if h.contains_single(side, line):
                    is_valid_inline = True
                    break

        if is_valid_inline:
            cand: Dict[str, Any] = {
                "path": file_path,
                "line": line,
                "side": side,
                "body": body,
            }
            if start_line is not None and start_side is not None:
                cand["start_line"] = start_line
                cand["start_side"] = start_side
            inline_candidates.append(cand)
        else:
            out_of_diff_notes.append(
                {
                    "path": file_path,
                    "line": line,
                    "start_line": start_line,
                    "side": side,
                    "start_side": start_side,
                    "body": body,
                }
            )

    # Dry-run handling
    if args.dry_run:
        print(f"[DRY-RUN] PR: {owner_repo}#{pr_number} (commit: {commit_id[:8]})")
        print(f"[DRY-RUN] Updates: {updated_count}, Deletions: {removed_count}")
        print(
            f"[DRY-RUN] In-diff inline additions: {len(inline_candidates)} (Duplicates skipped: {skipped_dup_count})"
        )
        for c in inline_candidates:
            if "start_line" in c:
                range_str = (
                    f"{c['start_line']}-{c['line']} ({c['start_side']}->{c['side']})"
                )
            else:
                range_str = f"{c['line']} ({c['side']})"
            print(f"  • {c['path']}:{range_str}: {c['body'][:80]}...")
        print(f"[DRY-RUN] Out-of-diff observations: {len(out_of_diff_notes)}")
        for o in out_of_diff_notes:
            line_str = f":{o['line']}" if o["line"] else ""
            print(f"  • {o['path']}{line_str}: {o['body'][:80]}...")
        return

    # 7. Construct review summary body
    obs_block = ""
    if out_of_diff_notes:
        obs_lines = []
        for o in out_of_diff_notes:
            if o.get("start_line"):
                loc = f"`{o['path']}:{o['start_line']}-{o['line']}`"
            elif o.get("line"):
                loc = f"`{o['path']}:{o['line']}`"
            else:
                loc = f"`{o['path']}`"
            obs_lines.append(f"- **{loc}**:\n  {o['body']}")
        obs_block = "### 🏛️ Out-of-Diff & Caller Observations\n\n" + "\n\n".join(
            obs_lines
        )

    initial_body = obs_block if obs_block else "Draft Review (Pending)"

    # 8. Create or Append to Pending Review
    staged_inline_count = 0

    if not pending:
        # Create review atomically with inline comments and initial body
        formatted_comments = []
        for c in inline_candidates:
            c_dict = {
                "path": c["path"],
                "line": c["line"],
                "side": c["side"],
                "body": c["body"],
            }
            if "start_line" in c:
                c_dict["start_line"] = c["start_line"]
                c_dict["start_side"] = c["start_side"]
            formatted_comments.append(c_dict)

        post_payload = {
            "commit_id": commit_id,
            "body": initial_body,
            "comments": formatted_comments,
        }
        api_request(
            "POST",
            f"/repos/{owner_repo}/pulls/{pr_number}/reviews",
            token,
            post_payload,
        )
        staged_inline_count = len(inline_candidates)
    else:
        # Pending review already exists: update body and append comments via GraphQL
        review_id = pending["id"]
        node_id = pending["node_id"]
        existing_body = pending.get("body") or ""

        if obs_block:
            updated_body = (
                f"{existing_body}\n\n{obs_block}".strip()
                if existing_body
                else obs_block
            )
            api_request(
                "PUT",
                f"/repos/{owner_repo}/pulls/{pr_number}/reviews/{review_id}",
                token,
                {"body": updated_body},
            )

        # Append inline comments via GraphQL
        mutation = """
        mutation($input: AddPullRequestReviewThreadInput!) {
          addPullRequestReviewThread(input: $input) {
            thread {
              id
            }
          }
        }
        """
        for c in inline_candidates:
            input_vars: Dict[str, Any] = {
                "pullRequestReviewId": node_id,
                "path": c["path"],
                "line": c["line"],
                "side": c["side"],
                "body": c["body"],
            }
            if "start_line" in c:
                input_vars["startLine"] = c["start_line"]
                input_vars["startSide"] = c["start_side"]

            try:
                graphql_request(mutation, {"input": input_vars}, token)
                staged_inline_count += 1
            except Exception as e:
                loc_desc = (
                    f"{c['path']}:{c['start_line']}-{c['line']}"
                    if "start_line" in c
                    else f"{c['path']}:{c['line']}"
                )
                fallback_msg = f"{c['body']}\n*(Note: Staged to summary as inline placement was rejected: {e})*"
                api_request(
                    "PUT",
                    f"/repos/{owner_repo}/pulls/{pr_number}/reviews/{review_id}",
                    token,
                    {
                        "body": f"{existing_body}\n\n- **`{loc_desc}`**:\n  {fallback_msg}"
                    },
                )

    # 9. Summary Output
    print(f"✓ Draft review reconciled on {owner_repo}#{pr_number}:")
    print(f"  • {staged_inline_count} new inline draft comments added")
    if updated_count > 0:
        print(f"  • {updated_count} existing draft comments updated in-place")
    if removed_count > 0:
        print(f"  • {removed_count} draft comments removed")
    if skipped_dup_count > 0:
        print(f"  • {skipped_dup_count} duplicate draft comments skipped")
    if out_of_diff_notes:
        print(
            f"  • {len(out_of_diff_notes)} out-of-diff observations attached to review summary"
        )
    print("  • State: PENDING (Private to you, zero notifications sent)")
    print(f"👉 Review and submit your drafts here: {pr_url}/files")


def main() -> None:
    repo_parser = argparse.ArgumentParser(add_help=False)
    repo_parser.add_argument(
        "--repo",
        "-R",
        help="Target repository in 'owner/repo' format (defaults to current git repo)",
    )

    parser = argparse.ArgumentParser(
        parents=[repo_parser],
        description="Stage draft PR review comments on GitHub without publishing.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: status
    parser_status = subparsers.add_parser(
        "status",
        parents=[repo_parser],
        help="Check status of active pending review",
    )
    parser_status.add_argument(
        "pr", type=int, nargs="?", help="PR number (defaults to current branch PR)"
    )

    # Subcommand: clear
    parser_clear = subparsers.add_parser(
        "clear",
        parents=[repo_parser],
        help="Delete active pending review and all draft comments",
    )
    parser_clear.add_argument(
        "pr", type=int, nargs="?", help="PR number (defaults to current branch PR)"
    )

    # Subcommand: stage
    parser_stage = subparsers.add_parser(
        "stage",
        parents=[repo_parser],
        help="Stage comments from JSON into a pending review",
    )
    parser_stage.add_argument(
        "pr", type=int, nargs="?", help="PR number (defaults to current branch PR)"
    )
    parser_stage.add_argument(
        "--file",
        "-f",
        dest="input_file",
        help="Path to JSON file with comments (defaults to stdin)",
    )
    parser_stage.add_argument(
        "--stdin", action="store_true", help="Explicitly read from stdin"
    )
    parser_stage.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate staging without calling GitHub API",
    )

    args = parser.parse_args()
    token = get_gh_token()

    if args.command == "status":
        cmd_status(args, token)
    elif args.command == "clear":
        cmd_clear(args, token)
    elif args.command == "stage":
        cmd_stage(args, token)


if __name__ == "__main__":
    main()
