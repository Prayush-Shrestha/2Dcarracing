extends Node2D
## Endless scrolling road. Builds lane dashes in code and moves them.
## Game sets road_speed to control difficulty.
## Visuals (colors, decor, weather, lighting) come from ThemeManager:
## each theme id maps to assets/themes/<id>/ + scripts/themes/.
## Backwards compatible: theme_for_index() / apply_theme_index() still
## work for old 0-4 saves via ThemeManager.migrate_legacy_index().

var road_speed: float = 420.0
var scrolling: bool = true

var road_left: float = 90.0
var road_right: float = 450.0
var lanes: Array[float] = [135.0, 225.0, 315.0, 405.0]

var _dashes: Array[ColorRect] = []
var _dash_color: Color = Color(0.9, 0.9, 0.88, 0.95)
var _theme_name: String = "ROCK MOUNTAIN"
var _theme_id: String = "rock_mountain"
var current_theme: Dictionary = {}

var _decor: ThemeDecor = null

@onready var dashes_root: Node2D = $Dashes
@onready var grass: ColorRect = $Grass
@onready var stripe_l: ColorRect = $GrassStripeL
@onready var stripe_r: ColorRect = $GrassStripeR
@onready var surface: ColorRect = $RoadSurface
@onready var edge_l: ColorRect = $EdgeLeft
@onready var edge_r: ColorRect = $EdgeRight


## Compat shim: old code passes 0-4 (HIGHWAY/DESERT/ICE/NIGHT/RAIN).
## New roster has 7 entries; legacy picks are migrated, direct 0-6 pass through.
static func theme_for_index(idx: int) -> Dictionary:
	var migrated := ThemeManager.migrate_legacy_index(idx) if idx <= 4 else clampi(idx, 0, ThemeManager.COUNT - 1)
	# Clamp raw 5/6 (new themes) also pass through.
	if idx >= 5:
		migrated = clampi(idx, 0, ThemeManager.COUNT - 1)
	var t: Dictionary = ThemeManager.get_by_index(migrated)
	# Old callers expect "name"/"handling_mod" + color keys only.
	return t


func _ready() -> void:
	_build_dashes()
	_ensure_decor()
	if current_theme.is_empty():
		current_theme = ThemeManager.get_by_index(0)
		_apply_weather_overlay()


func _process(delta: float) -> void:
	if not scrolling:
		return
	if get_tree().paused:
		return
	for d in _dashes:
		d.position.y += road_speed * delta
		if d.position.y > 980.0:
			d.position.y = -80.0
	if _decor != null:
		_decor.road_speed = road_speed


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


func _ensure_decor() -> void:
	if _decor != null and is_instance_valid(_decor):
		return
	_decor = ThemeDecor.new()
	_decor.name = "ThemeDecor"
	add_child(_decor)
	# Keep decor under the lane dashes so road props never cover markings.
	if dashes_root != null:
		move_child(_decor, dashes_root.get_index())


func apply_theme(t: Dictionary) -> void:
	current_theme = t
	grass.color = t.get("side", grass.color)
	stripe_l.color = t.get("side_dark", stripe_l.color)
	stripe_r.color = t.get("side_dark", stripe_r.color)
	surface.color = t.get("road", surface.color)
	edge_l.color = t.get("edge", edge_l.color)
	edge_r.color = t.get("edge", edge_r.color)
	_dash_color = t.get("dash", _dash_color)
	for d in _dashes:
		d.color = _dash_color
	_theme_name = str(t.get("name", "ROCK MOUNTAIN"))
	_theme_id = str(t.get("id", "rock_mountain"))
	_apply_weather_overlay()


func apply_theme_index(idx: int) -> void:
	apply_theme(theme_for_index(idx))


func apply_theme_id(theme_id: String) -> void:
	apply_theme(ThemeManager.get_by_id(theme_id))


func get_current_theme() -> Dictionary:
	return current_theme


func _apply_weather_overlay() -> void:
	_ensure_decor()
	ThemeWeather.apply(self, current_theme)
	if _decor != null:
		_decor.setup(current_theme)


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
