extends Area2D
## Enemy traffic car. Moves down, frees off-screen.
## Supports 5 types: normal, truck, bus, police, sports.
## Type changes size, color and speed feel; setup() keeps old
## 3-arg signature working for backward compatibility.

var speed: float = 300.0
var enemy_type: String = "normal"
var _wobble_phase: float = 0.0
var _wobble_amp: float = 0.0
var _wrecked: bool = false

@onready var body: Polygon2D = $Visuals/Body
@onready var collision: CollisionShape2D = $CollisionShape2D

const TYPE_COLORS := {
	# NOTE: traffic colors deliberately avoid the 3 bright player colors:
	# STARTER blue (0.18,0.55,1.0), SPORT red (0.85,0.2,0.22),
	# SUPER yellow (0.95,0.75,0.2) — so the player car always stands out.
	"normal": [Color(0.95, 0.62, 0.25), Color(0.42, 0.58, 0.58)],
	"truck": [Color(0.55, 0.58, 0.62), Color(0.55, 0.48, 0.38)],
	"bus": [Color(0.62, 0.58, 0.32), Color(0.58, 0.44, 0.30)],
	"police": [Color(0.20, 0.35, 0.95), Color(0.15, 0.25, 0.75)],
	"sports": [Color(0.55, 0.35, 0.78), Color(0.58, 0.28, 0.48)],
}


func _ready() -> void:
	add_to_group("enemy")
	_wobble_phase = randf() * TAU
	if randf() < 0.2:
		_wobble_amp = randf_range(10.0, 28.0)
	# The scene's RectangleShape2D is shared across instances: duplicate it
	# so per-type hitbox resizing below never leaks onto other cars.
	if collision != null and collision.shape != null:
		collision.shape = collision.shape.duplicate()
	_apply_type_visuals()


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	position.y += speed * delta
	if _wobble_amp > 0.0 and not _wrecked:
		_wobble_phase += delta * 2.0
		position.x += sin(_wobble_phase) * _wobble_amp * delta
	if position.y > 1060.0:
		queue_free()


## Crash response: spin off sideways and fade instead of blinking out.
## Drops out of the "enemy" group and disables collision at once so the
## wreck can't deal a second hit on its way out.
func wreck() -> void:
	if _wrecked:
		return
	_wrecked = true
	remove_from_group("enemy")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision.set_deferred("disabled", true)
	var dir := 1.0 if randf() < 0.5 else -1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "rotation", rotation + dir * randf_range(1.4, 2.4), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", position.x + dir * randf_range(70.0, 130.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(queue_free)


func setup(p_speed: float, lane_x: float, start_y: float = -70.0, p_type: String = "normal") -> void:
	speed = p_speed
	enemy_type = p_type
	position = Vector2(lane_x, start_y)
	# Type speed feel adjustment (kept subtle so levels stay fair).
	match enemy_type:
		"truck":
			speed *= 0.85
		"bus":
			speed *= 0.8
		"police":
			speed *= 1.25
		"sports":
			speed *= 1.4
	if is_node_ready():
		_apply_type_visuals()


func _apply_type_visuals() -> void:
	if body == null:
		return
	var palette: Array = TYPE_COLORS.get(enemy_type, TYPE_COLORS["normal"])
	body.color = palette[randi() % palette.size()]
	# Larger hitbox for truck/bus, sleeker for sports.
	# Boxes stay ~80% of the visuals (see index.html 0.7x precedent) so
	# near-miss grazes don't cost health unfairly.
	var rect := collision.shape as RectangleShape2D
	if rect != null:
		match enemy_type:
			"truck":
				rect.size = Vector2(34, 76)
				body.scale = Vector2(1.08, 1.3)
			"bus":
				rect.size = Vector2(36, 84)
				body.scale = Vector2(1.12, 1.42)
			"sports":
				rect.size = Vector2(28, 52)
				body.scale = Vector2(0.95, 0.92)
			_:
				rect.size = Vector2(30, 56)
				body.scale = Vector2.ONE
	# Police flashing light bar (code-drawn, no assets needed).
	if enemy_type == "police" and not has_node("Visuals/LightBar"):
		var bar := Polygon2D.new()
		bar.name = "LightBar"
		bar.color = Color(1.0, 0.2, 0.2)
		bar.polygon = PackedVector2Array([Vector2(-12, -11), Vector2(12, -11), Vector2(12, -5), Vector2(-12, -5)])
		$Visuals.add_child(bar)
		var tw := create_tween().set_loops()
		tw.tween_property(bar, "color", Color(0.2, 0.4, 1.0), 0.3)
		tw.tween_property(bar, "color", Color(1.0, 0.2, 0.2), 0.3)
