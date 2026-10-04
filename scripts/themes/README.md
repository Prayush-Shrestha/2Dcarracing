# Theme system — how it fits together

```
ThemeManager (scripts/themes/theme_manager.gd)   <- single source of truth
  THEMES[7]: id, name, colors, handling_mod, speed_mod,
             boost_zones, weather key, decor key, accent, dim
  get_by_index() / get_by_id() / migrate_legacy_index()

Road (scripts/world/road.gd)                     <- applies a theme
  apply_theme_id(id) / apply_theme_index(i) / apply_theme(dict)
    -> recolors Grass/Road/Edges/Dashes
    -> ThemeWeather.apply(self, theme)  (lighting + particles)
    -> ThemeDecor.setup(theme)          (scrolling roadside + road props)

ThemeDecor (scripts/themes/theme_decor.gd)       <- Node2D, ~18 pooled nodes
  _make_roadside() per "decor" key + _make_road_prop() on-road dressing
  scrolls with road_speed, recycles y=-70 -> 1030

ThemeWeather (scripts/themes/theme_weather.gd)   <- static helpers
  lighting ColorRect (theme["dim"]) + CPUParticles2D per "weather" key

Game (scripts/core/game.gd)
  _apply_level_theme(): GameManager.resolve_theme_id() wins override,
    handling *= handling_mod, speed *= speed_mod,
    boost strips tick for cyberpunk/space
  HUD distance line shows "LEVEL • THEME • m/m" when they differ

GameManager (scripts/core/game_manager.gd)
  pending_theme_id: "" = level default, else TRACKS free-race override
  start_theme_run(tree, theme_id, level=-1)

TRACKS picker (scripts/ui/themes.gd + scenes/menus/Themes.tscn)
  cards built from ThemeManager: preview strip, name, tagline,
  GRIP + hazard chips, SELECT (save) + RACE (play now)

LevelManager: 10 levels spread over all 7 environments.
SaveManager: selected_track clamped 0-6, legacy 0-4 migrated.
```

## Adding theme #8
1. Append dict to `ThemeManager.THEMES` (index = size).
2. Add `_make_<key>()` + road-prop branch in `theme_decor.gd`.
3. Add `when "<weather>":` branch in `theme_weather.gd`.
4. Create `assets/themes/<id>/README.txt` (copy rock_mountain's).
5. Optional: point a LevelManager level at the new theme_id.

## Performance notes
- Decor: max 18 Node2D holders, 1-3 Polygon2D/Rects each. No textures.
- Weather: CPUParticles2D, 50-220 particles, lifetime <= 1.4s.
- Lighting: 1-2 full-screen ColorRects with MOUSE_FILTER_IGNORE.
- Tested pattern matches existing Road rain/night overlay cost.
