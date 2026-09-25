# Street Rush

2D top-down endless car racer for Godot 4.x (Windows desktop first).

Dodge traffic, collect coins, level up. 3 hits per run. Esc pauses.

## Run

1. Open this folder in Godot 4.2+ (tested on 4.2 / 4.3, GL Compatibility).
2. Press F5 (MainMenu is the main scene).
3. PLAY -> drive with A/D or Left/Right arrows.

## Flow

Main Menu -> Garage -> select car -> Play -> dodge traffic ->
collect coins -> score -> complete level 1..10 (bonus each) ->
beat level 10 -> Victory -> Play Again / Main Menu.
Lose all health any time -> Game Over -> Restart / Main Menu.
Esc pauses anywhere in a run.

## Cars

- STARTER (free): Speed 60, Accel 60, Handling 80
- SPORT (500 coins): Speed 80, Accel 75, Handling 70
- SUPER (1500 coins): Speed 95, Accel 90, Handling 60

Coins persist across runs. High score, coin total, unlocked cars and
the selected car save to `user://street_rush_save.cfg`.

## Audio

No audio files are required. The game synthesizes click / coin / crash /
level / engine / game-over sounds in code. To use real clips, drop .wav
files into `assets/sounds/` (see the README there) - they are picked up
automatically when present.

## Structure

- `scenes/` - MainMenu, Game, Road, PlayerCar, EnemyCar, Coin,
  PauseMenu, GameOver, Victory, Garage (one scene per screen/entity)
- `scripts/` - one script per scene with matching responsibility
  (Game owns score/level/spawning, Player owns movement/health, etc.)
- `assets/` - optional art/sound drop-in folders
