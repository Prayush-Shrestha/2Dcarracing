class_name CarUpgrade
extends RefCounted
## Garage car data + upgrade costs. All coin math lives here so
## garage.gd and game.gd (apply stats) share one source of truth.

const MAX_UPGRADE := 3

const CARS: Array[Dictionary] = [
	{"name": "STARTER", "cost": 0, "speed": 60.0, "accel": 60.0,
		"handling": 80.0, "color": Color(0.18, 0.55, 1.0),
		"desc": "Balanced and easy to drive."},
	{"name": "SPORT", "cost": 500, "speed": 80.0, "accel": 75.0,
		"handling": 70.0, "color": Color(0.85, 0.2, 0.22),
		"desc": "Faster, a bit twitchy."},
	{"name": "SUPER", "cost": 1500, "speed": 95.0, "accel": 90.0,
		"handling": 60.0, "color": Color(0.95, 0.75, 0.2),
		"desc": "Very fast. Needs control."},
]

# Cost per upgrade step (level 0->1, 1->2, 2->3).
const UPGRADE_COSTS := [150, 350, 700]
const STAT_GAIN := 7.0


static func car_count() -> int:
	return CARS.size()


static func base_car(index: int) -> Dictionary:
	return CARS[clampi(index, 0, CARS.size() - 1)]


static func upgrades_for(data: Dictionary, car_index: int) -> Dictionary:
	var all: Dictionary = data.get("car_upgrades", {})
	var key := str(car_index)
	if all.has(key) and all[key] is Dictionary:
		var u: Dictionary = all[key]
		return {
			"speed": clampi(int(u.get("speed", 0)), 0, MAX_UPGRADE),
			"accel": clampi(int(u.get("accel", 0)), 0, MAX_UPGRADE),
			"handling": clampi(int(u.get("handling", 0)), 0, MAX_UPGRADE),
		}
	return {"speed": 0, "accel": 0, "handling": 0}


static func set_upgrade(data: Dictionary, car_index: int, stat: String, level: int) -> void:
	var all: Dictionary = data.get("car_upgrades", {})
	var key := str(car_index)
	if not all.has(key):
		all[key] = {"speed": 0, "accel": 0, "handling": 0}
	(all[key] as Dictionary)[stat] = clampi(level, 0, MAX_UPGRADE)
	data["car_upgrades"] = all


static func upgrade_cost(current_level: int) -> int:
	if current_level < 0 or current_level >= UPGRADE_COSTS.size():
		return -1
	return UPGRADE_COSTS[current_level]


static func effective_stats(car_index: int, upgrades: Dictionary) -> Dictionary:
	var base := base_car(car_index)
	return {
		"speed": float(base["speed"]) + float(upgrades.get("speed", 0)) * STAT_GAIN,
		"accel": float(base["accel"]) + float(upgrades.get("accel", 0)) * STAT_GAIN,
		"handling": float(base["handling"]) + float(upgrades.get("handling", 0)) * STAT_GAIN,
		"color": base["color"],
		"name": base["name"],
	}


static func stars(level: int) -> String:
	var s := ""
	for i in range(MAX_UPGRADE + 2):
		# 5-star display: base 2 stars + upgrade levels.
		var filled := 2 + level
		s += "★" if i < filled else "☆"
	return s
