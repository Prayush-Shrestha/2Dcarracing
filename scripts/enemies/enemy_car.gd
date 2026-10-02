extends Area2D
## Enemy traffic car. Moves down, frees off-screen.
## Supports 5 types: normal, truck, bus, police, sports.
## Type changes size, color and speed feel; setup() keeps old
## 3-arg signature working for backward compatibility.

var speed: float = 300.0
var enemy_type: String = "normal"
var _wobble_phase: float = 0.0
var _wobble_amp: float = 0.0

@onready var body: Polygon2D = $Visuals/Body
@onready var collision: CollisionShape2D = $CollisionShape2D

const TYPE_COLORS := {
	"normal": [Color(0.95, 0.62, 0.25), Color(0.25, 0.65, 0.85)],
	"truck": [Color(0.55, 0.58, 0.62), Color(0.45, 0.48, 0.52)],
	"bus": [Color(0.95, 0.75, 0.25), Color(0.90, 0.60, 0.20)],
	"police": [Color(0.20, 0.35, 0.95), Color(0.15, 0.25, 0.75)],
	"sports": [Color(0.90, 0.20, 0.30), Color(0.70, 0.15, 0.55)],
}


func _ready() -> void:
	add_to_group("enemy")
	_wobble_phase = randf() * TAU
	if randf() < 0.2:
		_wobble_amp = randf_range(10.0, 28.0)
	_apply_type_visuals()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	position.y += speed * delta
	if _wobble_amp > 0.0:
		_wobble_phase += delta * 2.0
		position.x += sin(_wobble_phase) * _wobble_amp * delta
	if position.y > 1060.0:
		queue_free()


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
	var rect := collision.shape as RectangleShape2D
	if rect != null:
		match enemy_type:
			"truck":
				rect.size = Vector2(40, 92)
				body.scale = Vector2(1.08, 1.3)
			"bus":
				rect.size = Vector2(42, 100)
				body.scale = Vector2(1.12, 1.42)
			"sports":
				rect.size = Vector2(34, 62)
				body.scale = Vector2(0.95, 0.92)
			_:
				rect.size = Vector2(36, 68)
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
