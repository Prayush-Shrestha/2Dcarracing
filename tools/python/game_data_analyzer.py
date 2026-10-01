"""Analyze Street Rush development/game statistics (dev-only tool).

Reads a save file copy (ConfigFile format) and/or a level JSON dump and
prints a short balance report. Never modifies the real user save.

Usage:
    python tools/python/game_data_analyzer.py [--save PATH] [--levels PATH]

The Godot save lives at user://street_rush_save.cfg. To analyze it, copy
it next to this tool or pass --save explicitly. If no file is given, the
tool analyzes the built-in level table only.
"""
from __future__ import annotations

import argparse
import configparser
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def parse_godot_cfg(path: Path) -> dict:
    """Parse a Godot ConfigFile (INI-like) into a flat dict of save/* keys."""
    raw = path.read_text(encoding="utf-8")
    # Godot headers look like [save]; configparser handles them fine.
    cp = configparser.ConfigParser()
    cp.read_string(raw)
    out: dict = {}
    if cp.has_section("save"):
        for k, v in cp.items("save"):
            out[k] = v
    return out


def summarize_levels(levels: list[dict]) -> None:
    print("=== LEVEL BALANCE ===")
    prev_dist = 0.0
    for lv in levels:
        gap = lv["distance"] - prev_dist
        time_est = lv["distance"] / 22.0  # ~22 m/s average cruise
        print(f'Lv {lv["number"]:>2} {lv["name"]:<18} '
              f'{lv["distance"]:>6.0f}m (+{gap:>4.0f})  '
              f'spawn {lv["spawn_interval"]:.2f}s  reward {lv["reward"]:>4}  '
              f'~{time_est:>4.0f}s/run  [{lv["difficulty"]}]')
        prev_dist = lv["distance"]
    total_reward = sum(lv["reward"] for lv in levels)
    print(f"Total campaign rewards: {total_reward} coins")


def summarize_save(save: dict) -> None:
    print("\n=== SAVE SUMMARY ===")
    for key in ["coins", "high_score", "current_level", "completed_levels",
                "unlocked_levels", "unlocked_cars", "selected_car",
                "selected_track", "total_coins_earned", "last_score",
                "last_coins", "last_level"]:
        print(f"  {key}: {save.get(key, '(missing)')}")
    try:
        completed = save.get("completed_levels", "[]")
        print(f"\nCampaign completion: {completed}")
    except Exception:
        pass


def main() -> None:
    ap = argparse.ArgumentParser(description="Analyze Street Rush data.")
    ap.add_argument("--save", type=Path, default=None)
    ap.add_argument("--levels", type=Path, default=None)
    args = ap.parse_args()

    levels: list[dict] = []
    if args.levels and args.levels.exists():
        levels = json.loads(args.levels.read_text(encoding="utf-8"))
    else:
        # Fall back to the generator table so the tool works with zero args.
        import sys
        sys.path.insert(0, str(HERE))
        from level_generator import LEVELS
        levels = LEVELS
    summarize_levels(levels)

    if args.save and args.save.exists():
        summarize_save(parse_godot_cfg(args.save))
    else:
        print("\n(no --save given; skipped save summary)")


if __name__ == "__main__":
    main()
