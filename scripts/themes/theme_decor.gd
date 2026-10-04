class_name ThemeDecor
extends Node2D
## Scrolling roadside + on-road dressing for every theme.
## Pure code-drawn Polygon2D/ColorRect shapes: zero textures,
## ~18 recycled nodes, safe for PC and mobile.
##
## Road owns one instance: road.gd calls setup(theme) on theme change.
## Add a new theme by adding one "_make_<decor>()" builder below and
## wiring it in _make_roadside() / _make_road_prop().

var road_speed: float = 420.0
var scrolling: bool = true

var _theme: Dictionary = {}
var _decor_key: String = "rock"
var _items: Array[Dictionary] = [] # {node: Node2D, mult: float}
var _gen: int = 0

const VIEW_H := 960.0
const ROAD_L := 90.0
const ROAD_R := 450.0


func setup(theme: Dictionary) -> void:
	_gen += 1
	var my_gen := _gen
	_theme = theme
	_decor_key = str(theme.get("decor", "rock"))
	for c in get_children():
		c.queue_free()
	_items.clear()
	await get_tree().process_frame
	if my_gen != _gen:
		return # superseded by a newer theme switch; drop this build.
	# 14 roadside objects (alternating left/right) + 4 subtle on-road props.
	for i in range(14):
		var side_left := (i % 2 == 0)
		_spawn_roadside(randf_range(-60.0, VIEW_H), side_left)
	for i in range(4):
		_spawn_road_prop(randf_range(-60.0, VIEW_H))


func _process(delta: float) -> void:
	if not scrolling or get_tree().paused:
		return
	for it in _items:
		var n: Node2D = it["node"]
		if not is_instance_valid(n):
			continue
		n.position.y += road_speed * float(it.get("mult", 1.0)) * delta
		if n.position.y > VIEW_H + 70.0:
			n.position.y = -70.0
			_recycle_x(n, bool(it.get("roadside", true)))


func _recycle_x(n: Node2D, roadside: bool) -> void:
	if roadside:
		var left_side: bool = randf() < 0.5
		if left_side:
			n.position.x = randf_range(6.0, ROAD_L - 16.0)
		else:
			n.position.x = randf_range(ROAD_R + 8.0, 534.0)
	else:
		n.position.x = randf_range(ROAD_L + 24.0, ROAD_R - 24.0)


func _spawn_roadside(y: float, side_left: bool) -> void:
	var holder := Node2D.new()
	var x := randf_range(6.0, ROAD_L - 16.0) if side_left else randf_range(ROAD_R + 8.0, 534.0)
	holder.position = Vector2(x, y)
	add_child(holder)
	_make_roadside(holder)
	_items.append({"node": holder, "mult": randf_range(0.96, 1.0), "roadside": true})


func _spawn_road_prop(y: float) -> void:
	var holder := Node2D.new()
	holder.position = Vector2(randf_range(ROAD_L + 24.0, ROAD_R - 24.0), y)
	add_child(holder)
	_make_road_prop(holder)
	# On-road props scroll exactly with the road so they read as painted on.
	_items.append({"node": holder, "mult": 1.0, "roadside": false})


# --- dispatch ---------------------------------------------------------------

func _make_roadside(holder: Node2D) -> void:
	match _decor_key:
		"desert":
			_make_desert(holder)
		"snow":
			_make_snow(holder)
		"forest":
			_make_forest(holder)
		"cyberpunk":
			_make_cyberpunk(holder)
		"volcano":
			_make_volcano(holder)
		"space":
			_make_space(holder)
		_:
			_make_rock(holder)


func _make_road_prop(holder: Node2D) -> void:
	match _decor_key:
		"desert":
			_sand_drift(holder)
		"snow":
			_snow_patch(holder)
		"forest":
			_leaf_patch(holder)
		"cyberpunk":
			_neon_lane_dot(holder)
		"volcano":
			_lava_crack(holder)
		"space":
			_alien_grid_dot(holder)
		_:
			_dirt_patch(holder)


# --- small shape helpers ----------------------------------------------------

func _poly(parent: Node2D, pts: PackedVector2Array, col: Color, pos := Vector2.ZERO) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.position = pos
	parent.add_child(p)
	return p


func _rect(parent: Node2D, size: Vector2, col: Color, pos := Vector2.ZERO) -> ColorRect:
	# ColorRect is a Control; offset it so pos is the center-ish anchor.
	var r := ColorRect.new()
	r.size = size
	r.color = col
	r.position = pos - size * 0.5
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _rock_shape(r: float, seed_f: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 6
	for i in range(n):
		var a := TAU * float(i) / float(n) + seed_f
		var rr := r * randf_range(0.7, 1.15)
		pts.append(Vector2(cos(a) * rr, sin(a) * rr * 0.8))
	return pts


# --- Theme 1: ROCK MOUNTAIN -------------------------------------------------
# Cliffs, boulders, caution posts, dirt patches. Falling-rock hazard is
# suggested by perched boulders + dust weather (see theme_weather.gd).

func _make_rock(holder: Node2D) -> void:
	var roll := randf()
	if roll < 0.45:
		_poly(holder, _rock_shape(randf_range(14.0, 26.0), randf() * TAU), Color(0.45, 0.40, 0.36))
		_poly(holder, _rock_shape(randf_range(6.0, 10.0), randf() * TAU), Color(0.55, 0.50, 0.45), Vector2(-4, -4))
	elif roll < 0.7:
		# Cliff slab: tall dark strata with light cap.
		_rect(holder, Vector2(randf_range(18.0, 30.0), randf_range(46.0, 80.0)), Color(0.36, 0.31, 0.28))
		_rect(holder, Vector2(20.0, 6.0), Color(0.52, 0.47, 0.41), Vector2(0, -24))
	else:
		# Caution post (narrow path marker).
		_rect(holder, Vector2(6, 26), Color(0.25, 0.22, 0.20))
		_rect(holder, Vector2(10, 8), Color(0.95, 0.75, 0.30), Vector2(0, -10))


func _dirt_patch(holder: Node2D) -> void:
	var r := _rect(holder, Vector2(randf_range(26.0, 60.0), randf_range(10.0, 18.0)), Color(0.32, 0.28, 0.24, 0.55))
	r.rotation = randf_range(-0.2, 0.2)


# --- Theme 2: DESERT RALLY --------------------------------------------------

func _make_desert(holder: Node2D) -> void:
	var roll := randf()
	if roll < 0.4:
		# Cactus.
		_rect(holder, Vector2(8, 34), Color(0.22, 0.45, 0.25))
		_rect(holder, Vector2(6, 16), Color(0.22, 0.45, 0.25), Vector2(-7, -4))
		_rect(holder, Vector2(6, 16), Color(0.25, 0.50, 0.28), Vector2(7, 2))
	elif roll < 0.7:
		# Dune mound.
		_poly(holder, PackedVector2Array([Vector2(-22, 8), Vector2(0, -10), Vector2(22, 8)]), Color(0.88, 0.77, 0.57))
	else:
		# Ruin pillar (ancient ruins + abandoned road).
		_rect(holder, Vector2(16, 44), Color(0.72, 0.63, 0.50))
		_rect(holder, Vector2(20, 6), Color(0.60, 0.51, 0.40), Vector2(0, -20))


func _sand_drift(holder: Node2D) -> void:
	_rect(holder, Vector2(randf_range(30.0, 70.0), randf_range(8.0, 14.0)), Color(0.80, 0.68, 0.48, 0.40))


# --- Theme 3: SNOW MOUNTAIN -------------------------------------------------

func _make_snow(holder: Node2D) -> void:
	var roll := randf()
	if roll < 0.5:
		# Snowy pine: dark green triangle + white cap.
		_poly(holder, PackedVector2Array([Vector2(0, -26), Vector2(-14, 8), Vector2(14, 8)]), Color(0.16, 0.34, 0.24))
		_poly(holder, PackedVector2Array([Vector2(0, -26), Vector2(-7, -12), Vector2(7, -12)]), Color(0.92, 0.95, 0.98))
		_rect(holder, Vector2(6, 12), Color(0.35, 0.26, 0.18), Vector2(0, 12))
	elif roll < 0.75:
		# Snow boulder.
		_poly(holder, _rock_shape(randf_range(12.0, 20.0), randf() * TAU), Color(0.88, 0.92, 0.96))
	else:
		# Frozen lake shard.
		_poly(holder, PackedVector2Array([Vector2(-20, 0), Vector2(0, -12), Vector2(20, 0), Vector2(0, 12)]), Color(0.62, 0.80, 0.92, 0.85))


func _snow_patch(holder: Node2D) -> void:
	_rect(holder, Vector2(randf_range(30.0, 64.0), randf_range(8.0, 14.0)), Color(0.90, 0.94, 0.98, 0.35))


# --- Theme 4: FOREST ADVENTURE ----------------------------------------------

func _make_forest(holder: Node2D) -> void:
	var roll := randf()
	if roll < 0.55:
		# Dense pine cluster.
		_poly(holder, PackedVector2Array([Vector2(0, -30), Vector2(-13, 2), Vector2(13, 2)]), Color(0.08, 0.30, 0.14))
		_poly(holder, PackedVector2Array([Vector2(-10, -14), Vector2(-20, 12), Vector2(0, 12)]), Color(0.10, 0.34, 0.16))
		_rect(holder, Vector2(6, 12), Color(0.30, 0.22, 0.14), Vector2(0, 14))
	elif roll < 0.8:
		# River segment.
		_rect(holder, Vector2(26, 40), Color(0.20, 0.42, 0.60, 0.9))
		_rect(holder, Vector2(26, 6), Color(0.55, 0.78, 0.90, 0.7), Vector2(0, -6))
	else:
		# Wooden bridge post.
		_rect(holder, Vector2(8, 30), Color(0.42, 0.30, 0.18))
		_rect(holder, Vector2(14, 5), Color(0.55, 0.40, 0.24), Vector2(0, -12))


func _leaf_patch(holder: Node2D) -> void:
	_rect(holder, Vector2(randf_range(24.0, 54.0), randf_range(8.0, 12.0)), Color(0.12, 0.28, 0.15, 0.5))


# --- Theme 5: CYBERPUNK CITY ------------------------------------------------

func _make_cyberpunk(holder: Node2D) -> void:
	var roll := randf()
	if roll < 0.5:
		# Skyscraper silhouette with lit windows.
		var h := randf_range(60.0, 110.0)
		_rect(holder, Vector2(26, h), Color(0.05, 0.06, 0.14))
		for wy in range(3):
			var wc := Color(0.1, 0.9, 1.0) if (wy + randi()) % 2 == 0 else Color(1.0, 0.3, 0.8)
			_rect(holder, Vector2(18, 3), wc, Vector2(0, -h * 0.3 + float(wy) * 12.0))
		_rect(holder, Vector2(26, 3), Color(1.0, 0.25, 0.75), Vector2(0, -h * 0.5))
	else:
		# Neon street pole.
		_rect(holder, Vector2(5, 44), Color(0.10, 0.10, 0.16))
		var nc := Color(0.1, 0.9, 1.0) if randf() < 0.5 else Color(1.0, 0.3, 0.8)
		_rect(holder, Vector2(9, 9), nc, Vector2(0, -18))


func _neon_lane_dot(holder: Node2D) -> void:
	# Boost-strip shimmer painted on the tarmac.
	var c := Color(0.1, 0.9, 1.0, 0.30) if randf() < 0.5 else Color(1.0, 0.3, 0.8, 0.30)
	_rect(holder, Vector2(46, 6), c)


# --- Theme 6: VOLCANO ZONE ---------------------------------------------------

func _make_volcano(holder: Node2D) -> void:
	var roll := randf()
	if roll < 0.5:
		# Burnt rock with glowing crack.
		_poly(holder, _rock_shape(randf_range(14.0, 24.0), randf() * TAU), Color(0.16, 0.12, 0.12))
		_rect(holder, Vector2(randf_range(10.0, 20.0), 3), Color(1.0, 0.42, 0.10), Vector2(0, 2))
	else:
		# Lava pool edge.
		_rect(holder, Vector2(28, 22), Color(0.20, 0.10, 0.08))
		_rect(holder, Vector2(20, 12), Color(1.0, 0.38, 0.08), Vector2(0, 2))
		_rect(holder, Vector2(10, 5), Color(1.0, 0.75, 0.20), Vector2(0, 2))


func _lava_crack(holder: Node2D) -> void:
	var r := _rect(holder, Vector2(randf_range(20.0, 44.0), 3), Color(1.0, 0.40, 0.10, 0.55))
	r.rotation = randf_range(-0.4, 0.4)


# --- Theme 7: SPACE / ALIEN --------------------------------------------------

func _make_space(holder: Node2D) -> void:
	var roll := randf()
	if roll < 0.5:
		# Alien crystal cluster.
		var cc := Color(0.35, 1.0, 0.80) if randf() < 0.5 else Color(0.70, 0.45, 1.0)
		_poly(holder, PackedVector2Array([Vector2(0, -26), Vector2(-8, 6), Vector2(8, 6)]), cc)
		_poly(holder, PackedVector2Array([Vector2(-12, -14), Vector2(-18, 8), Vector2(-6, 8)]), Color(cc.r, cc.g, cc.b, 0.7))
	else:
		# Floating rock shard.
		_poly(holder, _rock_shape(randf_range(10.0, 18.0), randf() * TAU), Color(0.30, 0.26, 0.44))
		_rect(holder, Vector2(12, 3), Color(0.45, 1.0, 0.85, 0.8), Vector2(0, 0))


func _alien_grid_dot(holder: Node2D) -> void:
	_rect(holder, Vector2(40, 5), Color(0.45, 1.0, 0.85, 0.28))
