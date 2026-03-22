#!/usr/bin/env python3
"""
Fix Markdown lint warnings in files.

Rules fixed in the files themselves:
  MD009 - No trailing spaces
  MD013 - Line length (wrap prose lines at word boundaries, skip code fences)
  MD022 - Headings must be surrounded by blank lines
  MD029 - Ordered list item prefix (fix numbering within contiguous runs)
  MD031 - Fenced code blocks must be surrounded by blank lines
  MD032 - Lists must be surrounded by blank lines
  MD040 - Fenced code blocks should have a language specified
  MD060 - Table separator column style (add spaces around pipes)
"""

from __future__ import annotations

import re
import sys
import textwrap
from pathlib import Path

FENCE_RE = re.compile(r"^(\s*)(`{3,}|~{3,})(.*)")
HEADING_RE = re.compile(r"^#{1,6}\s")
LIST_ITEM_RE = re.compile(r"^\s*([-*+]|\d+[.)]) ")
OL_ITEM_RE = re.compile(r"^(\s*)(\d+)([.)]) (.*)")
TABLE_SEP_RE = re.compile(r"^\|([:\- |]+)\|$")
MAX_LINE = 80


def _is_table_line(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("|") and stripped.endswith("|")


def _wrap_prose_line(line: str) -> list[str]:
    """Wrap a single prose line to MAX_LINE, preserving leading indent."""
    if len(line) <= MAX_LINE:
        return [line]

    # Detect leading whitespace
    stripped = line.lstrip()
    indent = len(line) - len(stripped)
    prefix = line[:indent]

    # Don't break markdown special lines
    # - Headings: just leave them (rarely > 80, and wrapping would break them)
    if HEADING_RE.match(stripped):
        return [line]
    # - Block quotes: wrap inside the quote
    if stripped.startswith(">"):
        inner = stripped[1:].lstrip()
        marker = prefix + "> "
        wrapped = textwrap.fill(
            inner,
            width=MAX_LINE,
            initial_indent=marker,
            subsequent_indent=marker,
        )
        return wrapped.split("\n")
    # - List items: wrap with continuation indent
    m = LIST_ITEM_RE.match(stripped)
    if m:
        marker_len = len(m.group(0))
        first_indent = prefix
        cont_indent = prefix + " " * marker_len
        wrapped = textwrap.fill(
            stripped,
            width=MAX_LINE,
            initial_indent=first_indent,
            subsequent_indent=cont_indent,
        )
        return wrapped.split("\n")
    # - Bold/italic lines that are standalone labels (e.g. "**something:**")
    # Leave short bold lines alone
    if stripped.startswith("**") and stripped.endswith("**") and len(stripped) < 120:
        return [line]
    # Regular prose
    wrapped = textwrap.fill(
        stripped,
        width=MAX_LINE - indent,
        initial_indent="",
        subsequent_indent="",
    )
    return [prefix + wl for wl in wrapped.split("\n")]


def _fix_table_separator(line: str) -> str:
    """MD060: ensure table separator has spaces around each cell.

    ``|------|--------:|:---:|`` → ``| ------ | --------: | :---: |``
    """
    stripped = line.strip()
    m = TABLE_SEP_RE.match(stripped)
    if not m:
        return line
    inner = m.group(1)
    # Split on pipe (delimiter between cells)
    cells = inner.split("|")
    fixed_cells: list[str] = []
    for cell in cells:
        cell = cell.strip()
        if not cell or set(cell) <= {"-"}:
            # Plain separator
            fixed_cells.append(f" {cell} ")
        elif cell.startswith(":") and cell.endswith(":"):
            fixed_cells.append(f" {cell} ")
        elif cell.startswith(":"):
            fixed_cells.append(f" {cell} ")
        elif cell.endswith(":"):
            fixed_cells.append(f" {cell} ")
        else:
            fixed_cells.append(f" {cell} ")
    return "|" + "|".join(fixed_cells) + "|"


def _fix_ordered_list_numbering(lines: list[str], types: list[str]) -> list[str]:
    """MD029: renumber ordered list items to use sequential 1/2/3 style.

    Within each contiguous run of ordered-list items (possibly separated
    by continuation text at the same indent), restart numbering from 1.
    """
    result = list(lines)
    i = 0
    while i < len(result):
        m = OL_ITEM_RE.match(result[i])
        if m and types[i] == "LIST_ITEM":
            indent = m.group(1)
            delim = m.group(3)
            counter = 1
            result[i] = f"{indent}{counter}{delim} {m.group(4)}"
            j = i + 1
            while j < len(result):
                m2 = OL_ITEM_RE.match(result[j])
                if m2 and m2.group(1) == indent and types[j] == "LIST_ITEM":
                    counter += 1
                    result[j] = f"{indent}{counter}{m2.group(3)} {m2.group(4)}"
                    j += 1
                elif types[j] in ("BLANK", "OTHER") or (
                    types[j] == "LIST_ITEM" and not OL_ITEM_RE.match(result[j])
                ):
                    # continuation or unordered sub-item — skip
                    j += 1
                else:
                    break
            i = j
        else:
            i += 1
    return result


def fix_markdown(text: str) -> str:
    lines = text.split("\n")

    # ── Pass 0: MD009 — strip trailing whitespace ────────────────────────────
    lines = [ln.rstrip() for ln in lines]

    # ── Pass 1: MD040 — add language tag to bare fences ──────────────────────
    in_fence = False
    fence_char = ""
    p1: list[str] = []
    for line in lines:
        stripped = line.strip()
        m = FENCE_RE.match(stripped)
        if m and not in_fence:
            in_fence = True
            fence_char = m.group(2)[0]
            lang = m.group(3).strip()
            if not lang:
                indent_len = len(line) - len(line.lstrip())
                line = " " * indent_len + m.group(2) + "text"
        elif m and in_fence and m.group(2)[0] == fence_char and not m.group(3).strip():
            in_fence = False
            fence_char = ""
        p1.append(line)

    lines = p1

    # ── Pass 1b: MD060 — fix table separator spacing ────────────────────────
    lines = [_fix_table_separator(ln) for ln in lines]

    # ── Pass 2: classify every line ──────────────────────────────────────────
    in_fence = False
    fence_char = ""
    types: list[str] = []
    for line in lines:
        stripped = line.strip()
        m = FENCE_RE.match(stripped)
        if m and not in_fence:
            in_fence = True
            fence_char = m.group(2)[0]
            types.append("FENCE_OPEN")
        elif m and in_fence and m.group(2)[0] == fence_char and not m.group(3).strip():
            in_fence = False
            fence_char = ""
            types.append("FENCE_CLOSE")
        elif in_fence:
            types.append("FENCE_CONTENT")
        elif not stripped:
            types.append("BLANK")
        elif HEADING_RE.match(stripped):
            types.append("HEADING")
        elif LIST_ITEM_RE.match(stripped):
            types.append("LIST_ITEM")
        elif _is_table_line(stripped):
            types.append("TABLE")
        else:
            types.append("OTHER")

    # ── Pass 3: MD013 — wrap long prose lines (skip fences/tables) ───────────
    wrapped_lines: list[str] = []
    wrapped_types: list[str] = []
    for line, typ in zip(lines, types, strict=True):
        if typ in ("FENCE_OPEN", "FENCE_CLOSE", "FENCE_CONTENT", "TABLE"):
            # Never wrap code or tables
            wrapped_lines.append(line)
            wrapped_types.append(typ)
        elif len(line) > MAX_LINE:
            parts = _wrap_prose_line(line)
            for j, part in enumerate(parts):
                wrapped_lines.append(part)
                wrapped_types.append(typ if j == 0 else "OTHER")
        else:
            wrapped_lines.append(line)
            wrapped_types.append(typ)

    lines = wrapped_lines
    types = wrapped_types

    # ── Pass 3b: MD029 — fix ordered list numbering ─────────────────────────
    lines = _fix_ordered_list_numbering(lines, types)

    # ── Pass 4: MD022/MD031/MD032 — insert blank lines ──────────────────────
    result: list[str] = []

    for i, (line, typ) in enumerate(zip(lines, types, strict=True)):
        prev = types[i - 1] if i > 0 else None
        nxt = types[i + 1] if i + 1 < len(types) else None

        needs_blank_before = (
            (typ == "HEADING" and i > 0 and prev != "BLANK")
            or (typ == "FENCE_OPEN" and i > 0 and prev != "BLANK")
            or (typ == "LIST_ITEM" and prev not in ("BLANK", "LIST_ITEM") and i > 0)
        )
        if needs_blank_before:
            result.append("")

        result.append(line)

        needs_blank_after = (
            (typ == "HEADING" and nxt not in ("BLANK", None))
            or (typ == "FENCE_CLOSE" and nxt not in ("BLANK", None))
            or (typ == "LIST_ITEM" and nxt not in ("BLANK", "LIST_ITEM", None))
        )
        if needs_blank_after:
            result.append("")

    # ── Pass 5: collapse consecutive blank lines ─────────────────────────────
    final: list[str] = []
    prev_blank = False
    for line in result:
        is_blank = not line.strip()
        if is_blank and prev_blank:
            continue
        prev_blank = is_blank
        final.append(line)

    while final and not final[0].strip():
        final.pop(0)

    # Ensure file ends with exactly one newline
    while final and not final[-1].strip():
        final.pop()
    final.append("")

    return "\n".join(final)


def main() -> None:
    paths = sys.argv[1:]
    if not paths:
        print("Usage: fix_markdown.py <file1.md> [file2.md ...]")
        sys.exit(1)
    for path_str in paths:
        path = Path(path_str)
        if not path.exists():
            print(f"NOT FOUND: {path}")
            continue
        original = path.read_text(encoding="utf-8")
        fixed = fix_markdown(original)
        if fixed != original:
            path.write_text(fixed, encoding="utf-8")
            print(f"Fixed:      {path.name}")
        else:
            print(f"No changes: {path.name}")


if __name__ == "__main__":
    main()
