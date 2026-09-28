#!/usr/bin/env python3
"""Validate this skill's own files; plain Python 3, no Blender needed, writes nothing.

  python validate_skill.py

Checks, relative to this script's skill folder:
  1. SKILL.md frontmatter: `name` equals the folder name (lowercase letters, digits, hyphens,
     at most 64 characters); `description` present, at most 1024 characters, no angle brackets.
  2. Every relative Markdown link in SKILL.md, references/*.md and scripts/README.md resolves
     to an existing file.
  3. Every file in references/ and every script in scripts/ is reachable from SKILL.md or
     scripts/README.md.
  4. The Claude compatibility entry <repo>/.claude/skills/<name>/SKILL.md exists, repeats the
     same name and description, links to THIS SKILL.md (the link resolves to the same file) and
     says it carries no independent rules -- the arrangement every other pointer in the repo uses.
  5. Every script compiles (built-in compile(), so no __pycache__ is written), and every Blender
     script's docstring shows its command line.
  6. SKILL.md stays an entry point: fewer than 500 lines.

Prints PASS/FAIL per check and exits 1 on any failure.
"""
from __future__ import annotations

import os
import re
import sys

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAME = os.path.basename(SKILL_DIR)
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")

results: list[tuple[bool, str]] = []


def check(ok: bool, label: str) -> None:
    results.append((ok, label))


def frontmatter(path: str) -> dict:
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    data = {}
    for line in lines[1:]:
        if line.strip() == "---":
            break
        key, sep, value = line.partition(":")
        if sep and not line.startswith((" ", "\t")):
            data[key.strip()] = value.strip()
    return data


def links(path: str) -> list[str]:
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    out = []
    for target in LINK.findall(text):
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        out.append(target.split("#", 1)[0])
    return [t for t in out if t]


def resolve(md: str, target: str) -> str:
    return os.path.normcase(os.path.normpath(os.path.join(os.path.dirname(md), target)))


def main() -> None:
    skill_md = os.path.join(SKILL_DIR, "SKILL.md")
    check(os.path.isfile(skill_md), "SKILL.md exists")
    fm = frontmatter(skill_md)
    name, desc = fm.get("name", ""), fm.get("description", "")
    check(name == NAME, f"frontmatter name {name!r} equals the folder name {NAME!r}")
    check(bool(re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?", name)), "name is lowercase-hyphen, <= 64 chars")
    check(0 < len(desc) <= 1024, f"description present and <= 1024 characters ({len(desc)})")
    check("<" not in desc and ">" not in desc, "description has no angle brackets")
    with open(skill_md, encoding="utf-8") as handle:
        n_lines = len(handle.read().splitlines())
    check(n_lines < 500, f"SKILL.md is an entry point: {n_lines} lines (< 500)")

    docs = [skill_md]
    ref_dir = os.path.join(SKILL_DIR, "references")
    if os.path.isdir(ref_dir):
        docs += [os.path.join(ref_dir, f) for f in sorted(os.listdir(ref_dir)) if f.endswith(".md")]
    readme = os.path.join(SKILL_DIR, "scripts", "README.md")
    if os.path.isfile(readme):
        docs.append(readme)
    reachable = set()
    for md in docs:
        for target in links(md):
            full = resolve(md, target)
            ok = os.path.exists(full)
            check(ok, f"{os.path.relpath(md, SKILL_DIR)} -> {target} resolves")
            if ok and md in (skill_md, readme):
                reachable.add(full)
    if os.path.isdir(ref_dir):
        for f in sorted(os.listdir(ref_dir)):
            full = os.path.normcase(os.path.normpath(os.path.join(ref_dir, f)))
            check(full in reachable, f"references/{f} is linked from SKILL.md or scripts/README.md")
    script_dir = os.path.join(SKILL_DIR, "scripts")
    for f in sorted(os.listdir(script_dir)):
        if not f.endswith(".py"):
            continue
        full = os.path.join(script_dir, f)
        check(os.path.normcase(os.path.normpath(full)) in reachable,
              f"scripts/{f} is linked from SKILL.md or scripts/README.md")
        with open(full, encoding="utf-8") as handle:
            source = handle.read()
        try:
            compile(source, full, "exec")
            compiled = True
        except SyntaxError as err:
            print(f"{f}: {err}")
            compiled = False
        check(compiled, f"scripts/{f} compiles")
        # Runnable Blender scripts only: a real `import bpy` line and an entry point. The shared
        # library is imported, not run, so it has no command line to document.
        if re.search(r"^import bpy\b", source, re.M) and "__main__" in source:
            doc = source.split('"""', 2)[1] if source.count('"""') >= 2 else ""
            check("blender" in doc.lower() and "--python" in doc,
                  f"scripts/{f} documents its Blender command line")
    check(not os.path.exists(os.path.join(script_dir, "__pycache__")),
          "no __pycache__ left in scripts/ (every script sets sys.dont_write_bytecode)")

    repo = os.path.dirname(os.path.dirname(os.path.dirname(SKILL_DIR)))
    pointer = os.path.join(repo, ".claude", "skills", NAME, "SKILL.md")
    check(os.path.isfile(pointer), f"Claude compatibility entry exists: {os.path.relpath(pointer, repo)}")
    if os.path.isfile(pointer):
        pfm = frontmatter(pointer)
        check(pfm.get("name") == name, "pointer repeats the same name")
        check(pfm.get("description") == desc, "pointer repeats the same description")
        targets = [resolve(pointer, t) for t in links(pointer)]
        check(os.path.normcase(os.path.normpath(skill_md)) in targets,
              "pointer links to this canonical SKILL.md (resolved path matches)")
        with open(pointer, encoding="utf-8") as handle:
            ptext = handle.read()
        check("no independent rules" in ptext and len(ptext) < 1500,
              "pointer states it carries no independent rules and stays short")

    failed = [label for ok, label in results if not ok]
    for ok, label in results:
        print(("PASS  " if ok else "FAIL  ") + label)
    print(f"{len(results) - len(failed)} passed, {len(failed)} failed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
