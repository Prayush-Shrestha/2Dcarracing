# Gameplay

## Controls

| Action | Keys |
|---|---|
| Steer left | `A` / `←` (`move_left`) |
| Steer right | `D` / `→` (`move_right`) |
| Nitro boost | `SPACE` (`nitro`) |
| Pause / resume | `ESC` (`pause`, `ui_cancel` also works) |

InputMap actions (`move_left, move_right, nitro, pause`) are defined in
`project.godot`. Gameplay also accepts the `ui_*` fallbacks and raw
keycodes so older saves/inputs keep working.

## Objective

Each level has a **required distance** (1000m → 6000m). Drive until the
progress bar fills. Collisions cost health; reaching zero ends the run.

```
LEVEL 3 — DESERT RUN
Distance: 1250 / 2000m   Progress: ██████░░░░
Score: 1840   Coins: 12   Health: ♥ ♥ ♡   Nitro: ██████░░
```

Level completion grants the coin reward, saves, unlocks the next level
and offers NEXT / LEVELS. Clearing level 10 shows the Championship
Victory screen.

## Health

- Start every run with **3 health** (`♥ ♥ ♥`).
- Each traffic hit: −1 health, crash particles + sound, screen shake +
  red flash, 1.5s invulnerability blink.
- **Shield** pickup blocks one hit (ring shown around the car), then
  breaks with a short 1.0s invulnerability.
- Health 0 → Game Over (run stats saved first).

## Coins & score

- Coins fall with the road; touching one: **+1 coin, +50 × level coin
  multiplier score**, sparkle + chime.
- Distance also scores passively (`road_speed × 0.055 /s`).
- Coin totals persist across runs and pay for cars/upgrades.

## Cars & upgrades

| Car | Price | Speed | Accel | Handling |
|---|---|---|---|---|
| STARTER | Free | 60 | 60 | 80 |
| SPORT | 500 | 80 | 75 | 70 |
| SUPER | 1500 | 95 | 90 | 60 |

Each stat upgrades **0 → 3** for **150 / 350 / 700 coins** (+7 per step).
Garage shows `Speed ★★☆☆☆`-style stars, current vs. cost, and only
sensible buttons (SELECT / UNLOCK / upgrade). Upgrades apply to the run
through `CarUpgrade.effective_stats()`.

## Nitro

Hold `SPACE` with meter above ~5%: **1.45× road speed**, flame trail,
rising engine pitch, `nitro` sound. Drains 42/s, recharges 16/s after a
1.2s delay. HUD shows `NITRO ██████░░`. No unlimited boost.

## Power-ups

Spawn about every 14s, alternating kinds:

- **SHIELD (S, blue)** — blocks the next crash, ring visible.
- **MAGNET (M, pink)** — pulls coins within 220px for 8s.

Both expire cleanly and never trivialize the game.

## Traffic

Types scale with level (see `EnemySpawner.pick_type`):

- **Normal** — balanced. **Truck** — large, slower. **Bus** — largest,
  slower. **Police** — fast + light bar (levels 8+). **Sports** — very
  fast.
- Spawning is **fair by construction**: at most 3 of 4 lanes, first car
  usually avoids your lane, speeds clamped 190–660. Difficulty comes
  from spawn interval (0.95s → 0.32s) and speed multiplier
  (1.0× → 1.6×), never from impossible walls.

## Tracks & handling

| Theme | Look | Handling |
|---|---|---|
| HIGHWAY | daylight, grey road | normal |
| DESERT | sand sides, red edges | normal |
| NIGHT | dark + amber lines, dim overlay | normal |
| ICE | snow sides, pale road | 0.70× grip — smooth inputs win |
| RAIN | wet road, rain particles | 0.88× grip — slightly loose |

Levels fix their own theme (e.g. Lv5 = ICE, Lv7 = RAIN, Lv10 =
CHAMPIONSHIP on highway visuals). The TRACKS screen stores a free-drive
preference used when it makes sense.

## Difficulty curve

| Lv | Name | Distance | Spawn | Reward |
|---|---|---|---|---|
| 1 | BEGINNER HIGHWAY | 1000m | 0.95s | 100 |
| 2 | CITY RUSH | 1500m | 0.87s | 150 |
| 3 | DESERT RUN | 2000m | 0.80s | 200 |
| 4 | NIGHT DRIVE | 2500m | 0.73s | 250 |
| 5 | ICE ROAD | 3000m | 0.66s | 300 |
| 6 | HEAVY TRAFFIC | 3500m | 0.58s | 400 |
| 7 | RAIN STORM | 4000m | 0.51s | 500 |
| 8 | POLICE CHASE | 4500m | 0.44s | 600 |
| 9 | STREET CHAOS | 5000m | 0.37s | 750 |
| 10 | CHAMPIONSHIP RACE | 6000m | 0.32s | 1000 |

Later levels are denser and faster but always leave a gap. If ICE/RAIN
feels frustrating, upgrade handling or pick the SUPER car.
