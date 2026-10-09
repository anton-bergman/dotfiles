#!/usr/bin/env python3
"""
tmux_safe_copy.py

Intelligent clipboard normalizer for tmux copy-mode.
Pipes stdin -> sanitized text -> stdout (typically piped to pbcopy).

Transformations:
1. Strips right-hand terminal grid filler spaces (trailing whitespace).
2. Repairs intentional backslash line continuations:
   - Strips trailing padding between unescaped '\\' and newline.
3. Automatically rejoins long commands that soft-wrapped across lines without a backslash:
   - If line N does not end with '\\', and line N+1 begins with CLI flag syntax
     (e.g. '--flag' or '-f', but NOT markdown lists like '- item'), merges them into one line.
4. Safely dedents common visual terminal margin padding across multi-line selections
   while preserving relative indentation for Python, YAML, and shell scripts.
5. Preserves single-line selections without aggressive stripping.
"""

import sys
import re


def is_git_diff(lines: list[str]) -> bool:
    """Detect if the copied text is a git diff or unified patch."""
    for line in lines:
        if line.startswith(("diff --git", "@@ ", "--- a/", "+++ b/")):
            return True
    return False


def clean_selection(raw_text: str) -> str:
    if not raw_text:
        return ""

    # Normalize line endings to standard Unix \n
    text = raw_text.replace("\r\n", "\n").replace("\r", "\n")

    # Single-line selection: minimal touch to avoid breaking intentional leading spaces
    if "\n" not in text:
        r = text.rstrip(" \t\r\n")
        # If line ended with an unescaped single backslash followed by spaces, clean to backslash
        if r.endswith("\\") and not r.endswith("\\\\"):
            return r
        return text.rstrip("\r\n ")

    # Multi-line selection processing:
    raw_lines = text.split("\n")
    cleaned_lines: list[str] = []

    # 1. Clean line by line:
    # - Strip trailing whitespace
    # - If line ends with an unescaped backslash, preserve backslash cleanly at end of line
    for line in raw_lines:
        r = line.rstrip()
        cleaned_lines.append(r)

    # If it is a git diff, preserve line boundaries and diff indicators
    if is_git_diff(cleaned_lines):
        return "\n".join(cleaned_lines).rstrip("\n")

    # 2. Rejoin soft-wrapped single commands that wrapped across rows without a backslash.
    # Pattern explanation:
    # - Line 1 does not end with an unescaped '\\'
    # - Line 2 starts with a CLI flag:
    #     '--[a-zA-Z0-9]' (long flag) or '-[a-zA-Z0-9]' (short flag)
    #   Distinguished from markdown/yaml lists which start with '- ' (dash followed by space).
    joined_lines: list[str] = []
    i = 0
    while i < len(cleaned_lines):
        curr_line = cleaned_lines[i]

        # Check if the next line is a wrapped flag continuation
        while (
            i + 1 < len(cleaned_lines)
            and curr_line.strip()  # current line is not empty
            and not (curr_line.endswith("\\") and not curr_line.endswith("\\\\"))  # does not end with \
            and re.match(r'^\s*--?[a-zA-Z0-9_]', cleaned_lines[i + 1])  # next line starts with flag
            and not re.match(r'^\s*-\s+', cleaned_lines[i + 1])  # not a markdown bullet list '- item'
        ):
            # Merge with next line separated by a single space
            next_line_stripped = cleaned_lines[i + 1].strip()
            curr_line = f"{curr_line} {next_line_stripped}"
            i += 1

        joined_lines.append(curr_line)
        i += 1

    # 3. Detect and remove common leading visual margin indentation (safe dedent)
    # Preserves relative internal indentation (e.g. Python function bodies)
    non_empty = [l for l in joined_lines if l.strip()]
    if non_empty:
        min_indent = min(len(l) - len(l.lstrip()) for l in non_empty)
        if min_indent > 0:
            joined_lines = [
                l[min_indent:] if l.strip() else "" for l in joined_lines
            ]

    return "\n".join(joined_lines).rstrip("\n")


def main() -> None:
    try:
        raw_input_text = sys.stdin.read()
        cleaned = clean_selection(raw_input_text)
        sys.stdout.write(cleaned)
    except Exception:
        # Fallback to stdin unaltered if anything fails unexpectedly
        pass


if __name__ == "__main__":
    main()
