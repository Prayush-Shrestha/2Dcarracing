extends Node2D
## Endless scrolling road. Builds lane dashes in code and moves them.
## Game sets road_speed to control difficulty. Themes change colors,
## handling and optional weather overlays (rain / night dim).

var road_speed: float = 420.0
var scrolling: bool = true

var road_left: float = 90.0
var road_right: float = 450.0
var lanes: Array[float] = [135.0, 225.0, 315.0, 405.0]

var _dashes: Array[ColorRect] = []
var _dash_color: Color = Color(0.9, 0.9, 0.88, 0.95)
var _theme_name: String = "HIGHWAY"
var _rain: CPUParticles2D = null
var _night_dim: ColorRect = null

@onready var dashes_root: Node2D = $Dashes
@onready var grass: ColorRect = $Grass
@onready var stripe_l: ColorRect = $GrassStripeL
@onready var stripe_r: ColorRect = $GrassStripeR
@onready var surface: ColorRect = $RoadSurface
@onready var edge_l: ColorRect = $EdgeLeft
@onready var edge_r: ColorRect = $EdgeRight


static func theme_for_index(idx: int) -> Dictionary:
	match clampi(idx, 0, 4):
		0:
			return {"name": "HIGHWAY", "handling_mod": 1.0,
				"side": Color(0.14, 0.32, 0.18), "side_dark": Color(0.12, 0.28, 0.16),
				"road": Color(0.17, 0.18, 0.20), "edge": Color(0.88, 0.88, 0.86),
				"dash": Color(0.9, 0.9, 0.88, 0.95)}
		1:
			return {"name": "DESERT", "handling_mod": 1.0,
				"side": Color(0.82, 0.71, 0.51), "side_dark": Color(0.74, 0.62, 0.44),
				"road": Color(0.33, 0.32, 0.31), "edge": Color(0.88, 0.27, 0.13),
				"dash": Color(0.96, 0.92, 0.80, 0.95)}
		2:
			return {"name": "ICE", "handling_mod": 0.7,
				"side": Color(0.74, 0.84, 0.91), "side_dark": Color(0.64, 0.75, 0.84),
				"road": Color(0.30, 0.36, 0.44), "edge": Color(0.92, 0.96, 1.0),
				"dash": Color(0.95, 0.98, 1.0, 0.95)}
		3:
			return {"name": "NIGHT", "handling_mod": 1.0,
				"side": Color(0.05, 0.07, 0.10), "side_dark": Color(0.04, 0.05, 0.08),
				"road": Color(0.10, 0.11, 0.13), "edge": Color(0.95, 0.70, 0.20),
				"dash": Color(0.95, 0.85, 0.55, 0.95)}
		_:
			return {"name": "RAIN", "handling_mod": 0.88,
				"side": Color(0.16, 0.22, 0.18), "side_dark": Color(0.12, 0.18, 0.15),
				"road": Color(0.19, 0.22, 0.26), "edge": Color(0.75, 0.82, 0.9),
				"dash": Color(0.85, 0.9, 0.95, 0.9)}


func _ready() -> void:
	_build_dashes()


func _process(delta: float) -> void:
	if not scrolling:
		return
	if get_tree().paused:
		return
	for d in _dashes:
		d.position.y += road_speed * delta
		if d.position.y > 980.0:
			d.position.y = -80.0


func _build_dashes() -> void:
	var divider_x: Array[float] = [180.0, 270.0, 360.0]
	var dash_h := 44.0
	var gap := 116.0
	for x in divider_x:
		for i in range(7):
			var r := ColorRect.new()
			r.color = _dash_color
			r.size = Vector2(6, dash_h)
			r.position = Vector2(x - 3.0, -80.0 + float(i) * (dash_h + gap))
			dashes_root.add_child(r)
			_dashes.append(r)


func apply_theme(t: Dictionary) -> void:
	grass.color = t.get("side", grass.color)
	stripe_l.color = t.get("side_dark", stripe_l.color)
	stripe_r.color = t.get("side_dark", stripe_r.color)
	surface.color = t.get("road", surface.color)
	edge_l.color = t.get("edge", edge_l.color)
	edge_r.color = t.get("edge", edge_r.color)
	_dash_color = t.get("dash", _dash_color)
	for d in _dashes:
		d.color = _dash_color
	_theme_name = str(t.get("name", "HIGHWAY"))
	_apply_weather_overlay()


func apply_theme_index(idx: int) -> void:
	apply_theme(theme_for_index(idx))


func _apply_weather_overlay() -> void:
	# Rain particles only for RAIN; soft dim only for NIGHT.
	if _rain != null:
		_rain.queue_free()
		_rain = null
	if _night_dim != null:
		_night_dim.queue_free()
		_night_dim = null
	if _theme_name == "RAIN":
		_rain = CPUParticles2D.new()
		_rain.amount = 220
		_rain.lifetime = 0.7
		_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_rain.emission_rect_extents = Vector2(270, 10)
		_rain.position = Vector2(270, -10)
		_rain.direction = Vector2(0.15, 1.0)
		_rain.spread = 8.0
		_rain.initial_velocity_min = 700.0
		_rain.initial_velocity_max = 950.0
		_rain.scale_amount_min = 1.0
		_rain.scale_amount_max = 2.0
		_rain.color = Color(0.65, 0.78, 0.95, 0.5)
		add_child(_rain)
	elif _theme_name == "NIGHT":
		_night_dim = ColorRect.new()
		_night_dim.color = Color(0.02, 0.03, 0.08, 0.28)
		_night_dim.position = Vector2.ZERO
		_night_dim.size = Vector2(540, 960)
		_night_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_night_dim)


func random_lane_x() -> float:
	return lanes[randi() % lanes.size()]


func lane_index_for_x(x: float) -> int:
	var best_i := 0
	var best_d := 99999.0
	for i in range(lanes.size()):
		var d := absf(lanes[i] - x)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i
