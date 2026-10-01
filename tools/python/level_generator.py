"""Generate level configuration data for Street Rush development.

Reads the canonical 10-level table (mirrors scripts/core/level_manager.gd)
and emits Godot-compatible output so designers can tweak distances,
rewards and difficulty without hand-editing GDScript.

Usage:
    python tools/python/level_generator.py [--format gdscript|json] [--out PATH]

Output is compatible with LevelManager.LEVELS (number, name, theme,
theme_index, distance, enemy_speed_mult, spawn_interval, coin_multiplier,
reward, difficulty, desc).
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

LEVELS: list[dict] = [
    {"number": 1, "name": "BEGINNER HIGHWAY", "theme": "HIGHWAY", "theme_index": 0,
     "distance": 1000.0, "enemy_speed_mult": 1.0, "spawn_interval": 0.95,
     "coin_multiplier": 1.0, "reward": 100, "difficulty": "Easy",
     "desc": "Slow traffic, wide gaps. Learn to steer."},
    {"number": 2, "name": "CITY RUSH", "theme": "HIGHWAY", "theme_index": 0,
     "distance": 1500.0, "enemy_speed_mult": 1.06, "spawn_interval": 0.87,
     "coin_multiplier": 1.05, "reward": 150, "difficulty": "Easy-Medium",
     "desc": "More traffic, slightly faster cars."},
    {"number": 3, "name": "DESERT RUN", "theme": "DESERT", "theme_index": 1,
     "distance": 2000.0, "enemy_speed_mult": 1.12, "spawn_interval": 0.80,
     "coin_multiplier": 1.1, "reward": 200, "difficulty": "Medium",
     "desc": "Hot sand, red-line road. Traffic thickens."},
    {"number": 4, "name": "NIGHT DRIVE", "theme": "NIGHT", "theme_index": 3,
     "distance": 2500.0, "enemy_speed_mult": 1.18, "spawn_interval": 0.73,
     "coin_multiplier": 1.15, "reward": 250, "difficulty": "Medium",
     "desc": "Dark road, amber lines. Faster flow."},
    {"number": 5, "name": "ICE ROAD", "theme": "ICE", "theme_index": 2,
     "distance": 3000.0, "enemy_speed_mult": 1.24, "spawn_interval": 0.66,
     "coin_multiplier": 1.2, "reward": 300, "difficulty": "Medium-Hard",
     "desc": "Slippery steering. Keep inputs smooth."},
    {"number": 6, "name": "HEAVY TRAFFIC", "theme": "HIGHWAY", "theme_index": 0,
     "distance": 3500.0, "enemy_speed_mult": 1.30, "spawn_interval": 0.58,
     "coin_multiplier": 1.3, "reward": 400, "difficulty": "Hard",
     "desc": "Trucks and buses. Gaps get smaller."},
    {"number": 7, "name": "RAIN STORM", "theme": "RAIN", "theme_index": 4,
     "distance": 4000.0, "enemy_speed_mult": 1.36, "spawn_interval": 0.51,
     "coin_multiplier": 1.4, "reward": 500, "difficulty": "Hard",
     "desc": "Wet road, rain, slightly loose grip."},
    {"number": 8, "name": "POLICE CHASE", "theme": "NIGHT", "theme_index": 3,
     "distance": 4500.0, "enemy_speed_mult": 1.44, "spawn_interval": 0.44,
     "coin_multiplier": 1.5, "reward": 600, "difficulty": "Very Hard",
     "desc": "Police interceptors. Fast and aggressive."},
    {"number": 9, "name": "STREET CHAOS", "theme": "MIXED", "theme_index": 0,
     "distance": 5000.0, "enemy_speed_mult": 1.52, "spawn_interval": 0.37,
     "coin_multiplier": 1.6, "reward": 750, "difficulty": "Very Hard",
     "desc": "Everything at once. Stay calm."},
    {"number": 10, "name": "CHAMPIONSHIP RACE", "theme": "CHAMPIONSHIP", "theme_index": 0,
     "distance": 6000.0, "enemy_speed_mult": 1.60, "spawn_interval": 0.32,
     "coin_multiplier": 1.75, "reward": 1000, "difficulty": "Final",
     "desc": "The final. Maximum traffic, top rewards."},
]


def to_gdscript(levels: list[dict]) -> str:
    lines = ["const LEVELS: Array[Dictionary] = ["]
    for lv in levels:
        lines.append("\t{")
        lines.append(f'\t\t"number": {lv["number"]}, "name": "{lv["name"]}", '
                     f'"theme": "{lv["theme"]}", "theme_index": {lv["theme_index"]},')
        lines.append(f'\t\t"distance": {lv["distance"]:.1f}, '
                     f'"enemy_speed_mult": {lv["enemy_speed_mult"]:.2f}, '
                     f'"spawn_interval": {lv["spawn_interval"]:.2f},')
        lines.append(f'\t\t"coin_multiplier": {lv["coin_multiplier"]:.2f}, '
                     f'"reward": {lv["reward"]}, "difficulty": "{lv["difficulty"]}",')
        lines.append(f'\t\t"desc": "{lv["desc"]}"')
        lines.append("\t},")
    lines.append("]")
    return "\n".join(lines)


def main() -> None:
    ap = argparse.ArgumentParser(description="Generate Street Rush level data.")
    ap.add_argument("--format", choices=["gdscript", "json"], default="json")
    ap.add_argument("--out", type=Path, default=None,
                    help="Write to file instead of stdout.")
    args = ap.parse_args()

    if args.format == "json":
        text = json.dumps(LEVELS, indent=2)
    else:
        text = to_gdscript(LEVELS)

    if args.out:
        args.out.write_text(text + "\n", encoding="utf-8")
        print(f"wrote {args.out} ({len(LEVELS)} levels)")
    else:
        print(text)


if __name__ == "__main__":
    main()
