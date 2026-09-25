extends Area2D
## Player car: smooth left/right movement, health, brief invulnerability.
## Game.gd applies the garage car stats with apply_car_stats().

signal health_changed(new_health: int)
signal died
signal bumped

const SAVE_PATH := "user://street_rush_save.cfg"

var max_health: int = 3
var health: int = 3

var lateral_speed: float = 400.0
var handling: float = 9.0
var road_left: float = 116.0
var road_right: float = 424.0
var fixed_y: float = 800.0

var _vel_x: float = 0.0
var _invuln: bool = false
var _invuln_left: float = 0.0
var _blink_t: float = 0.0
var _dead: bool = false

@onready var body: Polygon2D = $Visuals/Body
@onready var visuals: Node2D = $Visuals


func _ready() -> void:
	add_to_group("player")
	health = max_health
	position.y = fixed_y
	area_entered.connect(_on_area_entered)
	_apply_saved_color()


func _process(delta: float) -> void:
	if _dead:
		return
	if get_tree().paused:
		return

	var steer := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		steer -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		steer += 1.0

	var target := steer * lateral_speed
	_vel_x = lerp(_vel_x, target, clampf(handling * delta, 0.0, 1.0))
	position.x += _vel_x * delta
	position.x = clamp(position.x, road_left, road_right)
	position.y = fixed_y

	# Lean into the steering a little.
	rotation = lerp(rotation, steer * 0.14, clampf(10.0 * delta, 0.0, 1.0))

	_update_invuln(delta)


func apply_car_stats(car: Dictionary) -> void:
	# Stats are 0..100. Convert to real movement values.
	var spd := float(car.get("speed", 60))
	var hnd := float(car.get("handling", 70))
	lateral_speed = 300.0 + spd * 2.4
	handling = 5.0 + hnd * 0.07
	var col: Color = car.get("color", Color(0.18, 0.55, 1.0))
	if body:
		body.color = col


func take_damage() -> bool:
	if _dead or _invuln:
		return false
	health -= 1
	health_changed.emit(health)
	bumped.emit()
	if health <= 0:
		_dead = true
		died.emit()
	else:
		_invuln = true
		_invuln_left = 1.5
	return true


func heal_full() -> void:
	health = max_health
	_dead = false
	_invuln = false
	health_changed.emit(health)


func is_invulnerable() -> bool:
	return _invuln


func _update_invuln(delta: float) -> void:
	if not _invuln:
		visuals.modulate.a = 1.0
		return
	_invuln_left -= delta
	_blink_t += delta * 14.0
	visuals.modulate.a = 0.35 + 0.65 * (0.5 + 0.5 * sin(_blink_t))
	if _invuln_left <= 0.0:
		_invuln = false
		visuals.modulate.a = 1.0


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.is_in_group("enemy"):
		take_damage()


func _apply_saved_color() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var selected := int(cfg.get_value("save", "selected", 0))
	var col := Color(0.18, 0.55, 1.0)
	match selected:
		1:
			col = Color(0.85, 0.2, 0.22)
		2:
			col = Color(0.95, 0.75, 0.2)
	if body:
		body.color = col
