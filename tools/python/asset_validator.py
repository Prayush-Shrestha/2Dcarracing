"""Validate Street Rush project assets (report-only, never deletes).

Checks:
  - missing files referenced by .tscn ext_resources
  - missing expected folders
  - duplicate asset file names (case-insensitive)
  - unsupported file types inside assets/
  - orphan .import files without a source file

Usage:
    python tools/python/asset_validator.py [--root PATH]
"""
from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

EXT_RE = re.compile(r'path="(?P<path>res://[^"]+)"')

ALLOWED_EXTS = {
    ".wav", ".ogg", ".mp3",           # audio
    ".png", ".jpg", ".jpeg", ".webp", # images
    ".svg",                            # vector icon
    ".txt", ".md",                      # docs
    ".tscn", ".gd", ".godot", ".cfg",  # godot (only .tscn/.gd expected under scenes/scripts)
    ".import", ".uid",
}

EXPECTED_FOLDERS = [
    "assets/cars",
    "assets/sounds",
    "assets/ui",
    "scenes/main",
    "scenes/gameplay",
    "scenes/vehicles",
    "scenes/garage",
    "scenes/menus",
    "scripts/core",
    "scripts/player",
    "scripts/enemies",
    "scripts/world",
    "scripts/garage",
    "scripts/ui",
    "tools/python",
    "docs",
    "screenshots",
]


def main() -> None:
    ap = argparse.ArgumentParser(description="Validate Street Rush assets.")
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = ap.parse_args()
    root: Path = args.root
    problems: list[str] = []

    for folder in EXPECTED_FOLDERS:
        if not (root / folder).is_dir():
            problems.append(f"missing folder: {folder}")

    # Collect .tscn references.
    for tscn in sorted((root / "scenes").rglob("*.tscn")) if (root / "scenes").exists() else []:
        text = tscn.read_text(encoding="utf-8", errors="replace")
        for m in EXT_RE.finditer(text):
            rel = m.group("path").removeprefix("res://")
            if not (root / rel).exists():
                problems.append(f"{tscn.relative_to(root)}: missing {rel}")

    # Duplicate basenames + unsupported extensions under assets/.
    if (root / "assets").exists():
        names: Counter = Counter()
        IGNORED_DUPES = {"readme.txt", "readme.md", "license", "license.txt"}
        for f in (root / "assets").rglob("*"):
            if not f.is_file() or f.suffix == ".import":
                continue
            if f.name.lower() in IGNORED_DUPES:
                continue
            names[f.name.lower()] += 1
            if f.suffix.lower() not in ALLOWED_EXTS:
                problems.append(f"unsupported type: {f.relative_to(root)}")
        for name, count in names.items():
            if count > 1:
                problems.append(f"duplicate asset name x{count}: {name}")
        # Orphan .import files.
        for imp in (root / "assets").rglob("*.import"):
            src = imp.with_suffix("")  # foo.wav.import -> foo.wav
            # Godot import files keep full name: foo.wav.import -> foo.wav
            candidate = Path(str(imp)[: -len(".import")])
            if not candidate.exists():
                problems.append(f"orphan import (no source): {imp.relative_to(root)}")

    if problems:
        print(f"FOUND {len(problems)} problem(s):")
        for p in problems:
            print(f"  - {p}")
        raise SystemExit(1)
    print("assets OK: all references resolve, no duplicates, no unsupported types.")


if __name__ == "__main__":
    main()
