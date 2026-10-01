# Street Rush — Python development tools

> **Development-only.** The Godot game never requires Python to run.
> These scripts help with level design, balance analysis, asset hygiene
> and save-format checks. They only use the Python standard library.

## Requirements

- Python 3.10+ (tested on 3.11 / 3.12 / 3.13)
- No third-party packages — `pip install` is not needed.

Run from the project root (`Street-Rush/`):

```bash
python tools/python/level_generator.py --help
python tools/python/game_data_analyzer.py --help
python tools/python/asset_validator.py --help
python tools/python/save_data_checker.py --help
```

## Tools

### `level_generator.py`
Generates the canonical 10-level table so designers can tweak distances,
rewards and difficulty without hand-editing GDScript.

```bash
# Print JSON to stdout (default)
python tools/python/level_generator.py

# Emit GDScript CONST block for pasting into level_manager.gd
python tools/python/level_generator.py --format gdscript

# Write JSON to a file for the analyzer
python tools/python/level_generator.py --format json --out tools/python/levels.json
```

Output matches `LevelManager.LEVELS`: `number, name, theme, theme_index,
distance, enemy_speed_mult, spawn_interval, coin_multiplier, reward,
difficulty, desc`.

### `game_data_analyzer.py`
Balance + progress report. Never modifies saves.

```bash
# Level balance only (no save needed)
python tools/python/game_data_analyzer.py

# Include a copied save file
python tools/python/game_data_analyzer.py --save /tmp/street_rush_save.cfg

# Analyze a custom level JSON
python tools/python/game_data_analyzer.py --levels tools/python/levels.json
```

The live Godot save is at `user://street_rush_save.cfg` (outside the
project). Copy it somewhere and pass `--save` to inspect it.

### `asset_validator.py`
Reports missing scene references, duplicate asset names, unsupported
file types and orphan `.import` files. **Never deletes anything.**

```bash
python tools/python/asset_validator.py
python tools/python/asset_validator.py --root C:/path/to/Street-Rush
```

Exit code `0` = clean, `1` = problems found (listed on stdout).

### `save_data_checker.py`
Validates the save structure: required keys, ranges, level/car lists.
**Never modifies the file.**

```bash
python tools/python/save_data_checker.py --save /tmp/street_rush_save.cfg
```

Required keys: `coins, high_score, current_level, completed_levels,
unlocked_levels, unlocked_cars, selected_car, car_upgrades,
selected_track, music_volume, sfx_volume, muted`.

## Notes

- Godot does not call these scripts. They are for developers only.
- Keep generated `levels.json` out of version control unless sharing a
  balance proposal (it is git-ignored by default if you add it).
- The legacy `_makesfx.py` in the project root synthesizes the `.wav`
  set in `assets/sounds/`; the new tools do not replace it.
