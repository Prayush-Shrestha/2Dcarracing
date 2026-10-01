class_name LevelManager
extends RefCounted
## 10-level progression data for Street Rush.
## Distance-based: each level has a required distance in meters.
## Difficulty rises gradually via enemy speed + spawn interval.
## Rewards grow but never make later levels impossible.

const MAX_LEVEL := 10

# theme_index maps to Road theme order: 0 HIGHWAY, 1 DESERT, 2 ICE, 3 NIGHT, 4 RAIN.
const LEVELS: Array[Dictionary] = [
	{"number": 1, "name": "BEGINNER HIGHWAY", "theme": "HIGHWAY", "theme_index": 0,
		"distance": 1000.0, "enemy_speed_mult": 1.0, "spawn_interval": 0.95,
		"coin_multiplier": 1.0, "reward": 100, "difficulty": "Easy",
		"desc": "Slow traffic, wide gaps. Learn to steer."},
	{"number": 2, "name": "CITY RUSH", "theme": "HIGHWAY", "theme_index": 0,
		"distance": 1500.0, "enemy_speed_mult": 1.06, "spawn_interval": 0.87,
		"coin_multiplier": 1.05, "reward": 150, "difficulty": "Easy-Medium",
		"desc": "More traffic, slightly faster cars."},
	{"number": 3, "name": "DESERT RUN", "theme": "DESERT", "theme_index": 1,
		"distance": 2000.0, "enemy_speed_mult": 1.12, "spawn_interval": 0.80,
		"coin_multiplier": 1.1, "reward": 200, "difficulty": "Medium",
		"desc": "Hot sand, red-line road. Traffic thickens."},
	{"number": 4, "name": "NIGHT DRIVE", "theme": "NIGHT", "theme_index": 3,
		"distance": 2500.0, "enemy_speed_mult": 1.18, "spawn_interval": 0.73,
		"coin_multiplier": 1.15, "reward": 250, "difficulty": "Medium",
		"desc": "Dark road, amber lines. Faster flow."},
	{"number": 5, "name": "ICE ROAD", "theme": "ICE", "theme_index": 2,
		"distance": 3000.0, "enemy_speed_mult": 1.24, "spawn_interval": 0.66,
		"coin_multiplier": 1.2, "reward": 300, "difficulty": "Medium-Hard",
		"desc": "Slippery steering. Keep inputs smooth."},
	{"number": 6, "name": "HEAVY TRAFFIC", "theme": "HIGHWAY", "theme_index": 0,
		"distance": 3500.0, "enemy_speed_mult": 1.30, "spawn_interval": 0.58,
		"coin_multiplier": 1.3, "reward": 400, "difficulty": "Hard",
		"desc": "Trucks and buses. Gaps get smaller."},
	{"number": 7, "name": "RAIN STORM", "theme": "RAIN", "theme_index": 4,
		"distance": 4000.0, "enemy_speed_mult": 1.36, "spawn_interval": 0.51,
		"coin_multiplier": 1.4, "reward": 500, "difficulty": "Hard",
		"desc": "Wet road, rain, slightly loose grip."},
	{"number": 8, "name": "POLICE CHASE", "theme": "NIGHT", "theme_index": 3,
		"distance": 4500.0, "enemy_speed_mult": 1.44, "spawn_interval": 0.44,
		"coin_multiplier": 1.5, "reward": 600, "difficulty": "Very Hard",
		"desc": "Police interceptors. Fast and aggressive."},
	{"number": 9, "name": "STREET CHAOS", "theme": "MIXED", "theme_index": 0,
		"distance": 5000.0, "enemy_speed_mult": 1.52, "spawn_interval": 0.37,
		"coin_multiplier": 1.6, "reward": 750, "difficulty": "Very Hard",
		"desc": "Everything at once. Stay calm."},
	{"number": 10, "name": "CHAMPIONSHIP RACE", "theme": "CHAMPIONSHIP", "theme_index": 0,
		"distance": 6000.0, "enemy_speed_mult": 1.60, "spawn_interval": 0.32,
		"coin_multiplier": 1.75, "reward": 1000, "difficulty": "Final",
		"desc": "The final. Maximum traffic, top rewards."},
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
