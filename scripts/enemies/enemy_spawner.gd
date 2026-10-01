class_name EnemySpawner
extends RefCounted
## Fair traffic spawning. Never blocks every lane at once and always
## leaves the player a reachable gap. Difficulty comes from the
## LevelManager definition, not random impossibility.

# Enemy type ids used by enemy_car.gd.
const TYPE_NORMAL := "normal"
const TYPE_TRUCK := "truck"
const TYPE_BUS := "bus"
const TYPE_POLICE := "police"
const TYPE_SPORTS := "sports"


## Pick how many cars to spawn this tick for a given level.
static func pick_count(level_number: int) -> int:
	var count := 1
	if level_number >= 3 and randf() < 0.30:
		count = 2
	if level_number >= 6 and randf() < 0.12:
		count = 3
	if level_number >= 9 and randf() < 0.10:
		count = 3
	return mini(count, 3)


## Pick lanes that keep the game fair: skip the player's lane most of
## the time when spawning the first car, cap at 3 of 4 lanes.
static func pick_lanes(lanes: Array, player_lane: int, count: int) -> Array:
	var order: Array = lanes.duplicate()
	order.shuffle()
	var picked: Array = []
	for lx in order:
		if picked.size() >= count:
			break
		var li := _lane_index(lanes, float(lx))
		if li == player_lane and randf() < 0.75 and picked.is_empty() and count < 4:
			continue
		picked.append(float(lx))
	if picked.is_empty():
		picked.append(float(order[(player_lane + 2) % order.size()]))
	return picked


## Weighted enemy type for a level (later levels add police/sports/trucks).
static func pick_type(level_number: int) -> String:
	var r := randf()
	if level_number <= 2:
		return TYPE_NORMAL if r < 0.9 else TYPE_TRUCK
	if level_number <= 5:
		if r < 0.65:
			return TYPE_NORMAL
		if r < 0.80:
			return TYPE_TRUCK
		if r < 0.92:
			return TYPE_BUS
		return TYPE_SPORTS
	if level_number <= 7:
		if r < 0.50:
			return TYPE_NORMAL
		if r < 0.68:
			return TYPE_TRUCK
		if r < 0.82:
			return TYPE_BUS
		if r < 0.93:
			return TYPE_SPORTS
		return TYPE_POLICE
	# 8+: police chase + chaos mix.
	if r < 0.35:
		return TYPE_NORMAL
	if r < 0.52:
		return TYPE_TRUCK
	if r < 0.66:
		return TYPE_BUS
	if r < 0.84:
		return TYPE_POLICE
	return TYPE_SPORTS


static func _lane_index(lanes: Array, x: float) -> int:
	var best_i := 0
	var best_d := 99999.0
	for i in range(lanes.size()):
		var d := absf(float(lanes[i]) - x)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i
