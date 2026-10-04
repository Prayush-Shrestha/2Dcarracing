class_name SaveManager
extends RefCounted
## Central save system for Street Rush.
## Single owner of user://street_rush_save.cfg so gameplay, garage,
## menus and settings never duplicate ConfigFile logic.
##
## Backward compatible with the original save keys:
## high_score, total_coins, best_level, muted, selected/unlocked, theme,
## last_score, last_coins, last_level.

const SAVE_PATH := "user://street_rush_save.cfg"


static func default_data() -> Dictionary:
	return {
		"coins": 0,
		"high_score": 0,
		"current_level": 1,
		"completed_levels": [],
		"unlocked_levels": [1],
		"unlocked_cars": [0],
		"selected_car": 0,
		"car_upgrades": {},
		"selected_track": 0,
		"music_volume": 0.8,
		"sfx_volume": 0.9,
		"muted": false,
		"last_score": 0,
		"last_coins": 0,
		"last_level": 1,
		"last_distance": 0.0,
		"total_coins_earned": 0,
	}


static func load_data() -> Dictionary:
	var data: Dictionary = default_data()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return data
	# New keys first.
	for key: String in data.keys():
		# completed/unlocked lists need type care, handled below.
		if key in ["completed_levels", "unlocked_levels", "unlocked_cars", "car_upgrades"]:
			continue
		data[key] = cfg.get_value("save", key, data[key])
	# Lists (stored as Array).
	data["completed_levels"] = _to_int_array(cfg.get_value("save", "completed_levels", data["completed_levels"]))
	data["unlocked_levels"] = _to_int_array(cfg.get_value("save", "unlocked_levels", data["unlocked_levels"]))
	data["unlocked_cars"] = _to_int_array(cfg.get_value("save", "unlocked_cars", data["unlocked_cars"]))
	var upg = cfg.get_value("save", "car_upgrades", {})
	if upg is Dictionary:
		data["car_upgrades"] = upg
	# --- Migrate legacy keys (original build) ---
	if cfg.has_section_key("save", "total_coins"):
		data["coins"] = int(cfg.get_value("save", "total_coins", data["coins"]))
	if cfg.has_section_key("save", "selected"):
		data["selected_car"] = int(cfg.get_value("save", "selected", data["selected_car"]))
	if cfg.has_section_key("save", "unlocked"):
		var legacy_unlocked := _to_int_array(cfg.get_value("save", "unlocked", [0]))
		if not legacy_unlocked.is_empty():
			# Merge without wiping newer data.
			for c: int in legacy_unlocked:
				if not data["unlocked_cars"].has(c):
					data["unlocked_cars"].append(c)
	if cfg.has_section_key("save", "theme"):
		data["selected_track"] = ThemeManager.migrate_legacy_index(clampi(int(cfg.get_value("save", "theme", 0)), 0, 4))
	if cfg.has_section_key("save", "best_level"):
		var best := maxi(1, int(cfg.get_value("save", "best_level", 1)))
		data["current_level"] = maxi(int(data["current_level"]), mini(best, 10))
		for lv: int in range(1, best):
			if not data["completed_levels"].has(lv):
				data["completed_levels"].append(lv)
		for lv: int in range(1, mini(best + 1, 11)):
			if not data["unlocked_levels"].has(lv):
				data["unlocked_levels"].append(lv)
	# Sanitize.
	data["selected_car"] = clampi(int(data["selected_car"]), 0, 2)
	data["selected_track"] = clampi(int(data["selected_track"]), 0, ThemeManager.COUNT - 1)
	data["current_level"] = clampi(int(data["current_level"]), 1, 10)
	if (data["unlocked_levels"] as Array).is_empty():
		data["unlocked_levels"] = [1]
	if (data["unlocked_cars"] as Array).is_empty():
		data["unlocked_cars"] = [0]
	data["music_volume"] = clampf(float(data["music_volume"]), 0.0, 1.0)
	data["sfx_volume"] = clampf(float(data["sfx_volume"]), 0.0, 1.0)
	return data


static func save_data(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH) # keep unknown keys, ignore error
	for key: String in data.keys():
		cfg.set_value("save", key, data[key])
	# Keep legacy mirrors so older builds/tools still read the file.
	cfg.set_value("save", "total_coins", int(data.get("coins", 0)))
	cfg.set_value("save", "high_score", int(data.get("high_score", 0)))
	cfg.set_value("save", "selected", int(data.get("selected_car", 0)))
	cfg.set_value("save", "unlocked", data.get("unlocked_cars", [0]))
	cfg.set_value("save", "theme", int(data.get("selected_track", 0)))
	cfg.set_value("save", "muted", bool(data.get("muted", false)))
	var completed: Array = data.get("completed_levels", [])
	var best := 1
	for lv in completed:
		best = maxi(best, int(lv) + 1)
	best = mini(best, 10)
	cfg.set_value("save", "best_level", best)
	cfg.set_value("save", "last_score", int(data.get("last_score", 0)))
	cfg.set_value("save", "last_coins", int(data.get("last_coins", 0)))
	cfg.set_value("save", "last_level", int(data.get("last_level", 1)))
	cfg.save(SAVE_PATH)


static func reset_progress() -> void:
	var fresh: Dictionary = default_data()
	# Preserve audio prefs on reset (less surprising).
	var current := load_data()
	fresh["music_volume"] = current["music_volume"]
	fresh["sfx_volume"] = current["sfx_volume"]
	fresh["muted"] = current["muted"]
	save_data(fresh)


static func _to_int_array(raw: Variant) -> Array:
	var out: Array = []
	if raw is Array:
		for v in (raw as Array):
			# Guard against corrupt save entries like ["abc"].
			if v is int:
				out.append(v)
			elif v is float:
				out.append(int(v))
			elif v is String and (v as String).is_valid_int():
				out.append((v as String).to_int())
	return out
