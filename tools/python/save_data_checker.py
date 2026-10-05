"""Check Street Rush save-data structure during development.

Validates required keys, value ranges and list contents without ever
modifying the file. Pass a copied save file (Godot ConfigFile format).

Usage:
    python tools/python/save_data_checker.py [--save PATH]

Required keys: coins, high_score, current_level, completed_levels,
unlocked_levels, unlocked_cars, selected_car, car_upgrades,
selected_track, music_volume, sfx_volume, muted.
"""
from __future__ import annotations

import argparse
import ast
import configparser
from pathlib import Path

REQUIRED_KEYS = [
    "coins", "high_score", "current_level", "completed_levels",
    "unlocked_levels", "unlocked_cars", "selected_car", "car_upgrades",
    "selected_track", "music_volume", "sfx_volume", "muted",
]


def load_save(path: Path) -> dict:
    cp = configparser.ConfigParser()
    cp.read_string(path.read_text(encoding="utf-8"))
    if not cp.has_section("save"):
        return {}
    return dict(cp.items("save"))


def parse_value(raw: str):
    raw = raw.strip().strip('"')
    for conv in (int, float):
        try:
            return conv(raw)
        except ValueError:
            pass
    if raw.lower() in ("true", "false"):
        return raw.lower() == "true"
    try:
        return ast.literal_eval(raw)
    except Exception:
        return raw


def check(save: dict) -> list[str]:
    errors: list[str] = []
    for key in REQUIRED_KEYS:
        if key not in save:
            errors.append(f"missing key: {key}")
    if errors:
        return errors
    v = {k: parse_value(save[k]) for k in save}

    def num(key: str, lo: float, hi: float) -> None:
        try:
            x = float(v[key])
            if not (lo <= x <= hi):
                errors.append(f"{key}={v[key]!r} out of range [{lo},{hi}]")
        except (TypeError, ValueError):
            errors.append(f"{key}={v[key]!r} is not numeric")

    num("coins", 0, 999_999)
    num("high_score", 0, 99_999_999)
    num("current_level", 1, 10)
    num("selected_car", 0, 4)
    num("selected_track", 0, 4)
    num("music_volume", 0.0, 1.0)
    num("sfx_volume", 0.0, 1.0)

    for key in ("completed_levels", "unlocked_levels"):
        val = v[key]
        if not isinstance(val, list):
            errors.append(f"{key} should be an Array, got {val!r}")
        else:
            for lv in val:
                try:
                    if not (1 <= int(lv) <= 10):
                        errors.append(f"{key} has invalid level {lv!r}")
                except (TypeError, ValueError):
                    errors.append(f"{key} has invalid level {lv!r}")
    cars = v["unlocked_cars"]
    if not isinstance(cars, list):
        errors.append(f"unlocked_cars should be an Array, got {cars!r}")
    else:
        for c in cars:
            try:
                if int(c) not in (0, 1, 2, 3, 4):
                    errors.append(f"unlocked_cars has invalid car {c!r}")
            except (TypeError, ValueError):
                errors.append(f"unlocked_cars has invalid car {c!r}")
    if not isinstance(v["car_upgrades"], dict):
        errors.append(f"car_upgrades should be a Dictionary, got {v['car_upgrades']!r}")
    unlocked_levels = v["unlocked_levels"]
    if isinstance(unlocked_levels, list):
        try:
            if 1 not in [int(x) for x in unlocked_levels]:
                errors.append("unlocked_levels must always contain level 1")
        except (TypeError, ValueError):
            errors.append("unlocked_levels contains non-numeric entries")
    else:
        errors.append("unlocked_levels must always contain level 1")
    return errors


def main() -> None:
    ap = argparse.ArgumentParser(description="Check Street Rush save data.")
    ap.add_argument("--save", type=Path, default=None,
                    help="Path to a copied street_rush_save.cfg")
    args = ap.parse_args()
    if not args.save or not args.save.exists():
        print("No save file given (pass --save PATH). Checking defaults only.")
        print("To check a real save, copy user://street_rush_save.cfg and pass it here.")
        print("defaults OK: required key list has", len(REQUIRED_KEYS), "entries.")
        return
    save = load_save(args.save)
    errors = check(save)
    if errors:
        print(f"INVALID: {len(errors)} problem(s) in {args.save}:")
        for e in errors:
            print(f"  - {e}")
        raise SystemExit(1)
    print(f"save OK: {args.save.name} has all required keys with valid values.")


if __name__ == "__main__":
    main()
