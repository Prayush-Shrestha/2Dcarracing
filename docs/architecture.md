# Architecture

Street Rush is a Godot 4.x 2D top-down racer. GDScript owns the whole
game; Python in `tools/python/` is development-only and never runs
inside the game.

## Scene map

```
MainMenu ── PLAY ──> Game (level from GameManager.pending_level)
        ├── LEVELS ──> LevelSelect ── START ──> Game
        ├── GARAGE ──> select / unlock / upgrade cars
        ├── TRACKS ──> free-drive theme preference
        ├── SETTINGS ──> volumes + reset
        └── QUIT

Game ── distance reached ──> Level Complete panel ──> next Game
   ├── all 10 done ──> Victory (PLAY AGAIN / LEVELS / MENU)
   └── health 0 ──> Game Over (RESTART / LEVELS / MENU)
ESC pauses anywhere in a run (PauseMenu: RESUME / RESTART / SETTINGS / LEVELS / MENU).
```

Scene files live under `scenes/`: `main/`, `gameplay/`, `vehicles/`,
`garage/`, `menus/`. Each scene has one script with matching
responsibility.

## Core scripts (`scripts/core/`)

| File | Owns |
|---|---|
| `save_manager.gd` (`SaveManager`) | One owner of `user://street_rush_save.cfg`. Defaults, migration from legacy keys, load/save/reset. |
| `level_manager.gd` (`LevelManager`) | 10-level table (distance, theme, spawn, speed mult, coin mult, reward, difficulty) + unlock/complete helpers. |
| `game_manager.gd` (`GameManager`) | Static run context (`pending_level`, last run stats) + central scene paths + navigation helpers. No autoload needed. |
| `audio_manager.gd` (`AudioManager`) | Optional `.wav` lookup with synthesized fallback tones, engine loop builder, volume apply. |
| `game.gd` | Single run controller: distance/score loop, spawning timers, power-ups, nitro, HUD, pause, effects. Delegates data to the managers above. |

## Gameplay scripts

- `scripts/player/player_car.gd` — steering (InputMap `move_left` /
  `move_right` + `ui_*`/keys fallback), 3-hit health + invulnerability
  blink, nitro meter, shield ring, magnet timer.
- `scripts/player/nitro_system.gd` — reusable nitro model (drain /
  recharge / boost multiplier). Player embeds the same constants so the
  scene works without extra nodes.
- `scripts/enemies/enemy_car.gd` — traffic entity with 5 types
  (`normal, truck, bus, police, sports`): size/color/speed feel.
- `scripts/enemies/enemy_spawner.gd` — fair spawning: max 3 of 4 lanes,
  usually skips the player's lane, weighted type per level.
- `scripts/world/road.gd` — scrolling dashes, 5 themes (HIGHWAY, DESERT,
  ICE, NIGHT, RAIN) + rain particles + night dim. `apply_theme_index()`.
- `scripts/world/coin.gd` — falling collectible, `collected` signal.
- `scripts/world/powerups.gd` (`PowerUpDef`) — `shield`/`magnet`
  constants, durations, colors.
- `scripts/world/powerup_pickup.gd` — falling pickup entity, `picked`
  signal.

## Meta scripts

- `scripts/garage/garage.gd` + `car_upgrade.gd` (`CarUpgrade`) — 3 cars,
  coin unlock, per-stat upgrades (0–3, costs 150/350/700, +7 each),
  effective stats shared with the player.
- `scripts/ui/` — `main_menu.gd` (animated dashes, hover, PLAY/LEVELS/
  GARAGE/TRACKS/SETTINGS/QUIT), `level_select.gd` (10 cards with
  COMPLETED/UNLOCKED/LOCKED), `themes.gd` (5 track cards),
  `settings.gd` (music/SFX sliders, mute, confirmed reset),
  `pause_menu.gd` (overlay + quick volumes), `game_over.gd`,
  `victory.gd` (score/distance/coins + navigation).

## Data flow

1. Menus read/write through `SaveManager.load_data()` /
   `SaveManager.save_data(data)`.
2. `LevelSelect` calls `GameManager.start_level(tree, n)` which sets
   `pending_level` and opens `Game.tscn`.
3. `game.gd` loads the `LevelManager` definition for `pending_level`,
   applies the level theme + garage car (with upgrades), then runs the
   distance loop. Coins update `save.coins` live; level completion
   calls `LevelManager.complete_level()` and saves.
4. `GameOver`/`Victory` read `last_*` keys (+ `GameManager.last_*`
   fallback) for the summary.

## Conventions

- Typed GDScript, one responsibility per function, signals for
  health/death/pickups/pause, constants for tuning.
- Missing optional audio/image assets fall back to generated
  tones/code-drawn art — the game never crashes on absent files.
- UI uses anchors + containers (no hard-coded desktop positions) with
  `stretch = canvas_items / expand` so 540×960, 1280×720 and 1920×1080
  all work.
