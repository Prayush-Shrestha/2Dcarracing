extends Area2D
## Player car: smooth left/right movement, health, invulnerability,
## nitro boost, shield and coin-magnet power-up state.
## Game applies garage stats (with upgrades) via apply_car_stats().

signal health_changed(new_health: int)
signal died
signal bumped
signal shield_changed(active: bool)
signal magnet_changed(active: bool)
signal nitro_changed(value: float, max_value: float, active: bool)

var max_health: int = 3
var health: int = 3

var lateral_speed: float = 400.0
var handling: float = 9.0
var road_left: float = 116.0
var road_right: float = 424.0
var fixed_y: float = 800.0

var shield_active: bool = false
var magnet_active: bool = false
var nitro_active: bool = false

var _vel_x: float = 0.0
var _invuln: bool = false
var _invuln_left: float = 0.0
var _blink_t: float = 0.0
var _dead: bool = false
var _magnet_left: float = 0.0
var _nitro: float = 100.0
var _nitro_cool: float = 99.0
var _shield_ring: Polygon2D = null

const NITRO_MAX := 100.0
const NITRO_DRAIN := 42.0
const NITRO_RECHARGE := 16.0
const NITRO_DELAY := 1.2

@onready var body: Polygon2D = $Visuals/Body
@onready var visuals: Node2D = $Visuals


func _ready() -> void:
	add_to_group("player")
	health = max_health
	position.y = fixed_y
	area_entered.connect(_on_area_entered)
	_ensure_distinct_look()
	_apply_saved_color()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if get_tree().paused:
		return
	var steer := _read_steer()
	var target := steer * lateral_speed
	_vel_x = lerp(_vel_x, target, clampf(handling * delta, 0.0, 1.0))
	position.x += _vel_x * delta
	position.x = clamp(position.x, road_left, road_right)
	position.y = fixed_y
	rotation = lerp(rotation, steer * 0.14, clampf(10.0 * delta, 0.0, 1.0))
	_update_nitro(delta)
	_update_invuln(delta)
	_update_magnet(delta)
	_update_marker_bob(delta)
	_check_sustained_contact()


func _read_steer() -> float:
	var steer := 0.0
	# InputMap first (move_left/move_right), ui_* + raw keys as fallback.
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		steer -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		steer += 1.0
	return steer


func wants_nitro() -> bool:
	if Input.is_action_pressed("nitro") or Input.is_key_pressed(KEY_SPACE):
		return true
	return false


func apply_car_stats(car: Dictionary) -> void:
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
	if shield_active:
		set_shield(false)
		_invuln = true
		_invuln_left = 1.0
		bumped.emit()
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


func nitro_fraction() -> float:
	return _nitro / NITRO_MAX


func set_shield(on: bool) -> void:
	shield_active = on
	shield_changed.emit(shield_active)
	_refresh_shield_ring()


func set_magnet(duration: float) -> void:
	magnet_active = true
	_magnet_left = duration
	magnet_changed.emit(true)


func _update_nitro(delta: float) -> void:
	_nitro_cool += delta
	var want := wants_nitro() and _nitro > 5.0
	if want:
		_nitro = maxf(_nitro - NITRO_DRAIN * delta, 0.0)
		_nitro_cool = 0.0
		if _nitro <= 0.0:
			want = false
	elif _nitro_cool >= NITRO_DELAY:
		_nitro = minf(_nitro + NITRO_RECHARGE * delta, NITRO_MAX)
	var was := nitro_active
	nitro_active = want
	if was != nitro_active or Engine.get_process_frames() % 12 == 0:
		nitro_changed.emit(_nitro, NITRO_MAX, nitro_active)


func _update_magnet(delta: float) -> void:
	if not magnet_active:
		return
	_magnet_left -= delta
	if _magnet_left <= 0.0:
		magnet_active = false
		magnet_changed.emit(false)


func _refresh_shield_ring() -> void:
	if _shield_ring != null:
		_shield_ring.queue_free()
		_shield_ring = null
	if not shield_active:
		return
	_shield_ring = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		pts.append(Vector2(cos(a) * 30.0, sin(a) * 42.0))
	_shield_ring.polygon = pts
	_shield_ring.color = Color(0.35, 0.75, 1.0, 0.35)
	visuals.add_child(_shield_ring)
	visuals.move_child(_shield_ring, 0)


# --- player distinct look: yellow outline + rear spoiler + floating YOU arrow.
# Enemies have none of these, so the player car is identifiable at a glance
# even when body colors are close. Code-built so existing scenes get it too.
var _marker: Node2D = null
var _marker_t: float = 0.0

func _ensure_distinct_look() -> void:
	if visuals == null:
		return
	if not has_node("Visuals/PlayerOutline"):
		var outline := Polygon2D.new()
		outline.name = "PlayerOutline"
		outline.color = Color(1.0, 0.82, 0.15, 1.0)
		outline.polygon = PackedVector2Array([
			Vector2(-20, -37), Vector2(20, -37), Vector2(22, -18),
			Vector2(20, 37), Vector2(-20, 37), Vector2(-22, -18)])
		visuals.add_child(outline)
		visuals.move_child(outline, 0)
	if not has_node("Visuals/Spoiler"):
		var spoiler := Polygon2D.new()
		spoiler.name = "Spoiler"
		spoiler.color = Color(0.10, 0.12, 0.16, 1.0)
		spoiler.polygon = PackedVector2Array([
			Vector2(-21, 27), Vector2(21, 27),
			Vector2(21, 34), Vector2(-21, 34)])
		visuals.add_child(spoiler)
	if not has_node("PlayerMarker"):
		_marker = Node2D.new()
		_marker.name = "PlayerMarker"
		var chev := Polygon2D.new()
		chev.name = "Chevron"
		chev.color = Color(1.0, 0.82, 0.15, 1.0)
		chev.polygon = PackedVector2Array([
			Vector2(-10, -58), Vector2(10, -58), Vector2(0, -48)])
		_marker.add_child(chev)
		add_child(_marker)
	else:
		_marker = $PlayerMarker


func _update_marker_bob(delta: float) -> void:
	if _marker == null:
		return
	_marker_t += delta * 3.0
	_marker.position.y = sin(_marker_t) * 4.0


func _update_invuln(delta: float) -> void:
	if not _invuln:
		if not shield_active:
			visuals.modulate.a = 1.0
		return
	_invuln_left -= delta
	_blink_t += delta * 14.0
	visuals.modulate.a = 0.35 + 0.65 * (0.5 + 0.5 * sin(_blink_t))
	if _invuln_left <= 0.0:
		_invuln = false
		visuals.modulate.a = 1.0


func _on_area_entered(area: Area2D) -> void:
	_handle_enemy_contact(area)


## area_entered fires only once per overlap, so a car we survive inside
## of (invulnerability) would otherwise never hit us again. Poll every
## physics frame so sustained contact still lands once vulnerability
## returns. queue_free() is deferred, so freeing while iterating is safe.
func _check_sustained_contact() -> void:
	if _dead:
		return
	for area in get_overlapping_areas():
		_handle_enemy_contact(area)


func _handle_enemy_contact(area: Area2D) -> void:
	if _dead:
		return
	if not is_instance_valid(area) or not area.is_in_group("enemy"):
		return
	# Wreck the other car only when the hit lands (HP loss or shield
	# break). While invulnerable the enemy stays, so the poll above can
	# still punish sitting inside traffic.
	var vulnerable := not _invuln
	take_damage()
	if vulnerable:
		area.queue_free()


func _apply_saved_color() -> void:
	var data := SaveManager.load_data()
	var selected := int(data.get("selected_car", 0))
	var upgrades: Dictionary = CarUpgrade.upgrades_for(data, selected)
	var stats := CarUpgrade.effective_stats(selected, upgrades)
	if body:
		body.color = stats.get("color", Color(0.18, 0.55, 1.0))
