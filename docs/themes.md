# Environment Themes

Street Rush ships 7 racing environments. Each level has a fixed theme,
and the TRACKS screen offers free races in any environment.

| # | Theme | Level(s) | Grip | Weather | Gameplay |
|---|-------|----------|------|---------|----------|
| 1 | ROCK MOUNTAIN | 1 | Rugged x0.90 | dust | uneven off-road |
| 2 | DESERT RALLY | 2 | Loose x0.95 | sandstorm | sand drag x0.96 |
| 3 | FOREST ADVENTURE | 3 | Slick x0.85 | rain + fog | wet road |
| 4 | SNOW PEAK | 4 | Icy x0.65 | snow + fog | slippery |
| 5 | CYBERPUNK CITY | 5, 8 | Boost x1.00 | neon rain | boost strips |
| 6 | VOLCANO ZONE | 6, 9 | Rough x0.90 | embers + ash | cracked road |
| 7 | SPACE / ALIEN | 7, 10 | Floaty x1.00 | star drift | boost strips + x1.02 speed |

Changing a theme updates: ground/road/edge/dash colors, roadside decor,
on-road dressing, weather particles, lighting tint, handling, top speed,
and boost-strip behavior.

Files:
- `scripts/themes/theme_manager.gd` — registry
- `scripts/themes/theme_decor.gd` — scrolling objects
- `scripts/themes/theme_weather.gd` — particles + lighting
- `assets/themes/<id>/README.txt` — per-theme palette + sprite notes
- `scenes/menus/Themes.tscn` — picker (SELECT + RACE per card)
