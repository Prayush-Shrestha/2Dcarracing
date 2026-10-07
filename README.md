# Street Rush

2D top-down racing game for **Godot 4.x**. Dodge traffic, collect coins,
burn nitro, grab shield/magnet pickups and clear **10 levels** to win the
championship. Clean indie UI, garage with upgrades, 7 track themes,
persistent saves and synthesized audio that works with zero assets.

## Features

- 2D top-down racing with smooth keyboard steering
- 10-level progression (distance-based, gradual difficulty)
- Level unlock system with Level Select (completed / unlocked / locked)
- Garage: STARTER / SPORT / SUPER / VIPER / RAINBOW + per-stat upgrades
- 7 track themes: ROCK MOUNTAIN, DESERT RALLY, SNOW PEAK, FOREST ADVENTURE,
  CYBERPUNK CITY, VOLCANO ZONE, SPACE / ALIEN
- Traffic system: normal, truck, bus, police, sports cars (fair spawning)
- Coins with per-level multiplier + persistent totals
- Nitro boost (SPACE) with meter, flames and engine pitch
- Power-ups: SHIELD (blocks one crash), COIN MAGNET (8s pull)
- 3-hit health with crash FX, shake, flash and invulnerability
- Save system (`user://street_rush_save.cfg`): coins, scores, levels,
  cars, upgrades, track, settings
- Audio: engine loop, coin/crash/level/nitro/power-up/UI/game-over/
  victory (optional `.wav` + synthesized fallback)
- Settings: music/SFX volumes, mute, controls reference, confirmed reset
- Pause overlay (RESUME / RESTART / SETTINGS / LEVELS / MENU), ESC to pause
- Responsive UI (540×960, 1280×720, 1920×1080 via `canvas_items/expand`)

## Technology Stack

- **Godot 4.x** (GL Compatibility) — game engine
- **GDScript** — main game programming (all gameplay, UI, saves, audio)
- **Python** (stdlib only, 3.10+) — development tools only:
  level generation, data analysis, asset validation, save checking.
  The game runs from Godot with no Python required.

## Controls

```
A / D  or  Left / Right Arrow  — steer
SPACE                          — nitro boost
ESC                            — pause / resume
```

Also on screen: `II` pause button, `?` help panel.

## Game Flow

```
Main Menu → PLAY (continue) / LEVELS (pick) / GARAGE / TRACKS / SETTINGS
  → Select Level → Race (reach target distance)
  → Complete Level (+reward, unlock next) → Next Level …
  → Level 10 → Victory (PLAY AGAIN / LEVELS / MENU)
  Lose all health anytime → Game Over (RESTART / LEVELS / MENU)
```

## Screenshots

Capture these from Godot and drop them in `screenshots/`:

```
screenshots/main-menu.png
screenshots/garage.png
screenshots/level-select.png
screenshots/gameplay.png
screenshots/pause-menu.png
screenshots/game-over.png
screenshots/victory.png
```

No fake screenshots are bundled — the folder currently holds only
`.gitkeep`. The list above is the capture checklist.

## Gameplay Demo

No video is bundled. To record one: run the game (see below), play
levels 1–3, and capture with OBS / Windows Game Bar. Save as
`screenshots/demo.mp4` (git-ignored pattern — keep videos out of the
repo or link them from a release).

## Project Structure

```
Street-Rush/
├── assets/cars, road, sounds, ui   # optional drop-in art/audio (code-drawn by default)
├── scenes/
│   ├── main/MainMenu.tscn
│   ├── gameplay/Game.tscn, Road.tscn, LevelSelect.tscn
│   ├── vehicles/PlayerCar.tscn, EnemyCar.tscn, Coin.tscn, PowerUp.tscn
│   ├── garage/Garage.tscn
│   └── menus/PauseMenu.tscn, Settings.tscn, GameOver.tscn, Victory.tscn, Themes.tscn
├── scripts/
│   ├── core/game.gd, game_manager.gd, level_manager.gd, save_manager.gd, audio_manager.gd
│   ├── player/player_car.gd, nitro_system.gd
│   ├── enemies/enemy_car.gd, enemy_spawner.gd
│   ├── world/road.gd, coin.gd, powerups.gd, powerup_pickup.gd
│   ├── garage/garage.gd, car_upgrade.gd
│   └── ui/main_menu.gd, level_select.gd, themes.gd, settings.gd,
│           pause_menu.gd, game_over.gd, victory.gd
├── tools/python/                   # dev-only (never needed by the game)
│   ├── level_generator.py, game_data_analyzer.py,
│   │   asset_validator.py, save_data_checker.py, README.md
├── docs/architecture.md, gameplay.md, save-system.md
├── screenshots/  README.md  LICENSE  project.godot  icon.svg
└── _makesfx.py  index.html (legacy web prototype, not used by Godot)
```

## How to Run

1. Install **Godot 4.2+** (tested 4.3 / 4.7, GL Compatibility).
2. Open this folder in Godot (`project.godot` is the project file).
3. Press **F5** — `MainMenu` is the main scene.
4. `PLAY` continues at your unlocked level, `LEVELS` picks any unlocked
   level, `GARAGE` spends coins, `TRACKS` sets the free theme.

Optional audio: run `python _makesfx.py` to synthesize the full 9-file
`.wav` set into `assets/sounds/` (the game also works without them —
each missing file falls back to a synthesized tone in code).

## Release Checklist (v1.0.0)

Final-stage steps before tagging `v1.0.0`:

1. **Validate:** `python tools/python/asset_validator.py` and
   `python tools/python/game_data_analyzer.py` must pass.
2. **Playtest in Godot:** F5 → complete levels 1–10, check victory,
   game-over, pause (ESC), settings reset, garage purchases, save
   persistence (`user://street_rush_save.cfg`).
3. **Screenshots:** capture the 7 PNGs listed above into `screenshots/`.
4. **Export:** install Godot export templates (`Editor → Manage Export
   Templates`), then `Project → Export…` using `export_presets.cfg`
   (Windows / Web / Android — file is git-ignored by design, keep your
   local copy; Android needs a keystore for signing).
5. **Tag:** `git tag v1.0.0` + GitHub release with the exported builds.

## Development Tools

Python is **not** required to run the game — only for these helpers:

```bash
python tools/python/level_generator.py --format json --out tools/python/levels.json
python tools/python/game_data_analyzer.py
python tools/python/game_data_analyzer.py --save /tmp/street_rush_save.cfg
python tools/python/asset_validator.py
python tools/python/save_data_checker.py --save /tmp/street_rush_save.cfg
```

Details: `tools/python/README.md`.

## Credits

- Design, code, UI and synthesized audio: Street Rush contributors.
- Built with Godot 4.x + GDScript; Python helpers use stdlib only.
- No third-party art/music bundled. See `LICENSE` and
  `assets/*/README.txt` before adding external files.

## License

MIT — see `LICENSE`.
