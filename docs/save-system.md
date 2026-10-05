# Save system

## Location

`user://street_rush_save.cfg` — a Godot `ConfigFile` with one `[save]`
section. (`user://` is outside the project, per-platform; nothing to
commit.)

`SaveManager` (`scripts/core/save_manager.gd`) is the **only** writer.
Every screen loads with `SaveManager.load_data()`, mutates the
dictionary, and persists with `SaveManager.save_data(data)`.

## Saved values

| Key | Type | Default | Meaning |
|---|---|---|---|
| `coins` | int | `0` | Spendable total (also mirrored as legacy `total_coins`). |
| `high_score` | int | `0` | Best run score. |
| `current_level` | int | `1` | Highest level reached (1–10). |
| `completed_levels` | Array[int] | `[]` | Levels cleared. |
| `unlocked_levels` | Array[int] | `[1]` | Playable levels; completing N unlocks N+1. |
| `unlocked_cars` | Array[int] | `[0]` | Owned cars (0 STARTER, 1 SPORT, 2 SUPER, 3 VIPER, 4 RAINBOW). |
| `selected_car` | int | `0` | Active car (legacy mirror `selected`). |
| `car_upgrades` | Dictionary | `{}` | `{"0": {"speed": 1, ...}}` per car, 0–3 each. |
| `selected_track` | int | `0` | TRACKS preference 0–4 (legacy mirror `theme`). |
| `music_volume` | float | `0.8` | 0.0–1.0. |
| `sfx_volume` | float | `0.9` | 0.0–1.0. |
| `muted` | bool | `false` | Master mute. |
| `last_score` | int | `0` | Most recent run score. |
| `last_coins` | int | `0` | Coins earned in the most recent run. |
| `last_level` | int | `1` | Level of the most recent run. |
| `last_distance` | float | `0.0` | Meters driven in the most recent run. |
| `total_coins_earned` | int | `0` | Lifetime coins (for analysis). |

Legacy keys (`total_coins, selected, unlocked, theme, best_level,
last_score, last_coins, last_level`) are still read on load and written
as mirrors on save, so older builds and tools keep working.

## When data is saved

- Coin pickup — `coins` (+1) and HUD totals.
- Level complete — reward added, `completed/unlocked_levels` updated,
  `last_*` + `high_score` written.
- Game over / victory — `last_*`, `high_score`, `current_level`.
- Car unlock / select / upgrade — `coins`, `unlocked_cars`,
  `selected_car`, `car_upgrades`.
- Track select — `selected_track`.
- Settings change — `music_volume` / `sfx_volume` / `muted` immediately.
- Pause quick-settings sliders — volumes immediately.

Every write goes through `SaveManager.save_data()`, which also refreshes
the legacy mirrors.

## Defaults & missing file

If the file is absent or corrupt, `load_data()` returns safe defaults:
level 1 unlocked, STARTER selected, volumes 0.8/0.9, everything else
zero/empty. The game starts cleanly with no crash. Invalid values are
clamped (`selected_car` 0–4, `selected_track` 0–4, `current_level`
1–10, volumes 0–1, empty unlock lists reset to `[1]`/`[0]`).

## Reset behavior

`Settings → RESET PROGRESS` shows an inline confirmation
(`YES, ERASE / CANCEL`) — one click never wipes data. Confirming calls
`SaveManager.reset_progress()`, which restores defaults **but keeps
audio prefs**. The pause overlay has no reset button by design.

## Inspecting a save (dev)

```bash
# Copy the live file, then validate / summarize:
python tools/python/save_data_checker.py --save /tmp/street_rush_save.cfg
python tools/python/game_data_analyzer.py --save /tmp/street_rush_save.cfg
```

The checker reports missing keys, out-of-range values and bad lists and
never modifies the file.
