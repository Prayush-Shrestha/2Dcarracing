class_name ThemeManager
extends RefCounted
## Central registry for all race environment themes.
##
## HOW TO ADD A NEW THEME (3 steps):
## 1. Append a new Dictionary to THEMES below (copy an existing entry).
##    Keep "index" == position in the array, give it a unique "id".
## 2. Add decor builders in theme_decor.gd (match on the new "decor" key).
## 3. Add weather in theme_weather.gd (match on the new "weather" key).
## 4. Create assets/themes/<your_id>/README.txt (palette + sprite drop-in notes).
## No other file needs editing: Road, Game, LevelSelect and the
## track picker read everything from here.

const COUNT := 7

# Field guide per theme dict:
# id: stable string used by GameManager.pending_theme_id + assets/themes/<id>/
# name: big display title. tagline: short flavor. desc/hazard: picker card text.
# handling_mod: multiplies player handling ( <1 = slippery/heavy ).
# speed_mod: multiplies base road speed ( sand drag, boost-friendly tarmac... ).
# boost_zones: cyberpunk/space get periodic 2s overdrive windows in game.gd.
# side/side_dark/road/edge/dash: road.gd colors. accent: UI + preview color.
# dim: full-screen lighting tint applied by theme_weather.gd.
# weather: key consumed by theme_weather.gd.
# decor: key consumed by theme_decor.gd.
# NOTE: static var (not const) so Color()/array literals always parse.
static var THEMES: Array[Dictionary] = [
	{
		"id": "rock_mountain", "index": 0, "name": "ROCK MOUNTAIN", "tagline": "EXTREME OFF-ROAD",
		"desc": "Rocky cliffs, dirt track, falling-rock country. Uneven grip, pure adventure.",
		"hazard": "Rockfall decor + uneven grip", "handling_label": "Rugged",
		"handling_mod": 0.9, "speed_mod": 1.0, "boost_zones": false,
		"side": Color(0.42, 0.35, 0.30), "side_dark": Color(0.33, 0.28, 0.24),
		"road": Color(0.27, 0.24, 0.22), "edge": Color(0.95, 0.75, 0.32),
		"dash": Color(0.98, 0.93, 0.74, 0.95), "accent": Color(0.92, 0.52, 0.22),
		"dim": Color(0.0, 0.0, 0.0, 0.0), "weather": "dust", "decor": "rock",
	},
	{
		"id": "desert_rally", "index": 1, "name": "DESERT RALLY", "tagline": "SANDSTORM SPRINT",
		"desc": "Sand dunes, cracked ruins, dry lakebed road. Sand drag slows top speed.",
		"hazard": "Sand drag + dust storm", "handling_label": "Loose",
		"handling_mod": 0.95, "speed_mod": 0.96, "boost_zones": false,
		"side": Color(0.82, 0.71, 0.51), "side_dark": Color(0.72, 0.60, 0.42),
		"road": Color(0.36, 0.32, 0.28), "edge": Color(0.88, 0.30, 0.13),
		"dash": Color(0.97, 0.92, 0.78, 0.95), "accent": Color(1.0, 0.60, 0.18),
		"dim": Color(0.55, 0.35, 0.12, 0.10), "weather": "sandstorm", "decor": "desert",
	},
	{
		"id": "snow_mountain", "index": 2, "name": "SNOW PEAK", "tagline": "FROZEN DESCENT",
		"desc": "Snowfields, frozen lakes, whiteout gusts. Very slippery — steer smooth.",
		"hazard": "Ice physics + snowfall + fog", "handling_label": "Icy",
		"handling_mod": 0.65, "speed_mod": 0.98, "boost_zones": false,
		"side": Color(0.74, 0.84, 0.91), "side_dark": Color(0.62, 0.73, 0.83),
		"road": Color(0.30, 0.36, 0.44), "edge": Color(0.92, 0.96, 1.0),
		"dash": Color(0.95, 0.98, 1.0, 0.95), "accent": Color(0.45, 0.78, 1.0),
		"dim": Color(0.60, 0.75, 0.95, 0.08), "weather": "snow", "decor": "snow",
	},
	{
		"id": "forest_adventure", "index": 3, "name": "FOREST ADVENTURE", "tagline": "RAINY WOODLAND",
		"desc": "Dense pines, river crossings, wooden posts. Wet leaves, rain, slick road.",
		"hazard": "Rain + slick grip + fog", "handling_label": "Slick",
		"handling_mod": 0.85, "speed_mod": 0.98, "boost_zones": false,
		"side": Color(0.10, 0.26, 0.14), "side_dark": Color(0.07, 0.19, 0.11),
		"road": Color(0.17, 0.19, 0.20), "edge": Color(0.72, 0.80, 0.88),
		"dash": Color(0.86, 0.91, 0.86, 0.92), "accent": Color(0.32, 0.82, 0.42),
		"dim": Color(0.04, 0.10, 0.08, 0.18), "weather": "rain", "decor": "forest",
	},
	{
		"id": "cyberpunk_city", "index": 4, "name": "CYBERPUNK CITY", "tagline": "NEON NIGHT RACE",
		"desc": "Skyscrapers, neon grid, glowing tarmac. Night race with boost strips.",
		"hazard": "Night + boost zones", "handling_label": "Boost",
		"handling_mod": 1.0, "speed_mod": 1.0, "boost_zones": true,
		"side": Color(0.06, 0.05, 0.12), "side_dark": Color(0.04, 0.03, 0.09),
		"road": Color(0.10, 0.10, 0.17), "edge": Color(0.05, 0.90, 1.0),
		"dash": Color(1.0, 0.38, 0.85, 0.95), "accent": Color(1.0, 0.25, 0.75),
		"dim": Color(0.02, 0.04, 0.12, 0.30), "weather": "neon_rain", "decor": "cyberpunk",
	},
	{
		"id": "volcano_zone", "index": 5, "name": "VOLCANO ZONE", "tagline": "LAVA ERUPTION",
		"desc": "Burning rock, lava pools, ashfall. Destroyed road, dramatic red glow.",
		"hazard": "Embers + cracked road", "handling_label": "Rough",
		"handling_mod": 0.9, "speed_mod": 1.0, "boost_zones": false,
		"side": Color(0.20, 0.11, 0.10), "side_dark": Color(0.13, 0.07, 0.07),
		"road": Color(0.23, 0.16, 0.15), "edge": Color(1.0, 0.36, 0.10),
		"dash": Color(1.0, 0.70, 0.30, 0.95), "accent": Color(1.0, 0.32, 0.08),
		"dim": Color(0.45, 0.08, 0.03, 0.22), "weather": "embers", "decor": "volcano",
	},
	{
		"id": "space_alien", "index": 6, "name": "SPACE / ALIEN", "tagline": "LOW-GRAVITY PLANET",
		"desc": "Teal crystals, floating rock, starfield. Alien tarmac with boost strips.",
		"hazard": "Low gravity + boost zones", "handling_label": "Floaty boost",
		"handling_mod": 1.0, "speed_mod": 1.02, "boost_zones": true,
		"side": Color(0.13, 0.09, 0.24), "side_dark": Color(0.09, 0.06, 0.17),
		"road": Color(0.19, 0.17, 0.30), "edge": Color(0.45, 1.0, 0.88),
		"dash": Color(0.60, 1.0, 0.88, 0.95), "accent": Color(0.35, 1.0, 0.80),
		"dim": Color(0.08, 0.03, 0.20, 0.28), "weather": "stars", "decor": "space",
	},
]


static func count() -> int:
	return THEMES.size()


static func get_by_index(idx: int) -> Dictionary:
	return THEMES[clampi(idx, 0, THEMES.size() - 1)]


static func get_by_id(theme_id: String) -> Dictionary:
	for t in THEMES:
		if str(t.get("id", "")) == theme_id:
			return t
	return THEMES[0]


static func index_of_id(theme_id: String) -> int:
	for t in THEMES:
		if str(t.get("id", "")) == theme_id:
			return int(t.get("index", 0))
	return 0


## Old 5-theme saves (0 HIGHWAY, 1 DESERT, 2 ICE, 3 NIGHT, 4 RAIN)
## map onto the new 7-theme roster without breaking anyone's pick.
static func migrate_legacy_index(idx: int) -> int:
	match idx:
		0:
			return 0 # HIGHWAY -> ROCK MOUNTAIN (new default off-road)
		1:
			return 1 # DESERT stays DESERT RALLY
		2:
			return 2 # ICE stays SNOW PEAK
		3:
			return 4 # NIGHT -> CYBERPUNK CITY
		4:
			return 3 # RAIN -> FOREST ADVENTURE
		_:
			return clampi(idx, 0, COUNT - 1)
