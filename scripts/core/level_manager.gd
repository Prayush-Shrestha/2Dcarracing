class_name LevelManager
extends RefCounted
## 10-level progression data for Street Rush.
## Distance-based: each level has a required distance in meters.
## Difficulty rises gradually via enemy speed + spawn interval.
## Rewards grow but never make later levels impossible.
##
## theme_id maps to ThemeManager (scripts/themes/) + assets/themes/<id>/.
## theme_index mirrors ThemeManager order so Road can apply it directly.

const MAX_LEVEL := 10

const LEVELS: Array[Dictionary] = [
	{"number": 1, "name": "ROCK TRAIL", "theme": "ROCK MOUNTAIN", "theme_id": "rock_mountain", "theme_index": 0,
		"distance": 1000.0, "enemy_speed_mult": 1.0, "spawn_interval": 0.95,
		"coin_multiplier": 1.0, "reward": 100, "difficulty": "Easy",
		"desc": "Rocky cliffs, dirt track. Learn to steer off-road."},
	{"number": 2, "name": "DESERT RALLY", "theme": "DESERT RALLY", "theme_id": "desert_rally", "theme_index": 1,
		"distance": 1500.0, "enemy_speed_mult": 1.06, "spawn_interval": 0.87,
		"coin_multiplier": 1.05, "reward": 150, "difficulty": "Easy-Medium",
		"desc": "Sand dunes, ruins, dust storm. Sand drag slows you."},
	{"number": 3, "name": "FOREST RUN", "theme": "FOREST ADVENTURE", "theme_id": "forest_adventure", "theme_index": 3,
		"distance": 2000.0, "enemy_speed_mult": 1.12, "spawn_interval": 0.80,
		"coin_multiplier": 1.1, "reward": 200, "difficulty": "Medium",
		"desc": "Dense pines, rain, slick leaves. Smooth inputs."},
	{"number": 4, "name": "SNOW DESCENT", "theme": "SNOW PEAK", "theme_id": "snow_mountain", "theme_index": 2,
		"distance": 2500.0, "enemy_speed_mult": 1.18, "spawn_interval": 0.73,
		"coin_multiplier": 1.15, "reward": 250, "difficulty": "Medium",
		"desc": "Frozen lakes, snowfall, fog. Very slippery."},
	{"number": 5, "name": "NEON RUSH", "theme": "CYBERPUNK CITY", "theme_id": "cyberpunk_city", "theme_index": 4,
		"distance": 3000.0, "enemy_speed_mult": 1.24, "spawn_interval": 0.66,
		"coin_multiplier": 1.2, "reward": 300, "difficulty": "Medium-Hard",
		"desc": "Night city, neon grid. Hit the boost strips."},
	{"number": 6, "name": "VOLCANO CLIMB", "theme": "VOLCANO ZONE", "theme_id": "volcano_zone", "theme_index": 5,
		"distance": 3500.0, "enemy_speed_mult": 1.30, "spawn_interval": 0.58,
		"coin_multiplier": 1.3, "reward": 400, "difficulty": "Hard",
		"desc": "Lava pools, embers, cracked tarmac. Stay calm."},
	{"number": 7, "name": "ALIEN CROSSING", "theme": "SPACE / ALIEN", "theme_id": "space_alien", "theme_index": 6,
		"distance": 4000.0, "enemy_speed_mult": 1.36, "spawn_interval": 0.51,
		"coin_multiplier": 1.4, "reward": 500, "difficulty": "Hard",
		"desc": "Low gravity, crystals, boost strips. Floaty but fast."},
	{"number": 8, "name": "POLICE CHASE", "theme": "CYBERPUNK CITY", "theme_id": "cyberpunk_city", "theme_index": 4,
		"distance": 4500.0, "enemy_speed_mult": 1.44, "spawn_interval": 0.44,
		"coin_multiplier": 1.5, "reward": 600, "difficulty": "Very Hard",
		"desc": "Police interceptors in the neon city. Fast and aggressive."},
	{"number": 9, "name": "ERUPTION CHAOS", "theme": "VOLCANO ZONE", "theme_id": "volcano_zone", "theme_index": 5,
		"distance": 5000.0, "enemy_speed_mult": 1.52, "spawn_interval": 0.37,
		"coin_multiplier": 1.6, "reward": 750, "difficulty": "Very Hard",
		"desc": "Everything burns. Maximum traffic on broken road."},
	{"number": 10, "name": "GALACTIC FINAL", "theme": "SPACE / ALIEN", "theme_id": "space_alien", "theme_index": 6,
		"distance": 6000.0, "enemy_speed_mult": 1.60, "spawn_interval": 0.32,
		"coin_multiplier": 1.75, "reward": 1000, "difficulty": "Final",
		"desc": "The final. Alien championship, top rewards."},
]


static func count() -> int:
	return LEVELS.size()


static func get_level(number: int) -> Dictionary:
	var n := clampi(number, 1, MAX_LEVEL)
	return LEVELS[n - 1]


static func is_unlocked(number: int, unlocked: Array) -> bool:
	return unlocked.has(clampi(number, 1, MAX_LEVEL))


static func is_completed(number: int, completed: Array) -> bool:
	return completed.has(clampi(number, 1, MAX_LEVEL))


## Mark a level complete: adds to completed, unlocks next, returns next level or -1.
static func complete_level(number: int, data: Dictionary) -> int:
	var n := clampi(number, 1, MAX_LEVEL)
	var completed: Array = data.get("completed_levels", [])
	var unlocked: Array = data.get("unlocked_levels", [1])
	if not completed.has(n):
		completed.append(n)
	data["completed_levels"] = completed
	if n < MAX_LEVEL and not unlocked.has(n + 1):
		unlocked.append(n + 1)
	data["unlocked_levels"] = unlocked
	data["current_level"] = mini(n + 1, MAX_LEVEL)
	if n >= MAX_LEVEL:
		return -1
	return n + 1
