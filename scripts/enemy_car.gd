extends Area2D
## Enemy traffic car. Moves down, slight drift on some cars, frees off-screen.

var speed: float = 300.0
var _wobble_phase: float = 0.0
var _wobble_amp: float = 0.0

@onready var body: Polygon2D = $Visuals/Body

const COLORS: Array[Color] = [
	Color(0.95, 0.62, 0.25),
	Color(0.25, 0.65, 0.85),
	Color(0.5, 0.75, 0.4),
	Color(0.6, 0.6, 0.65),
	Color(0.88, 0.48, 0.38),
	Color(0.7, 0.55, 0.9),
]


func _ready() -> void:
	add_to_group("enemy")
	_wobble_phase = randf() * TAU
	if randf() < 0.2:
		_wobble_amp = randf_range(10.0, 28.0)
	if body:
		body.color = COLORS[randi() % COLORS.size()]


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	position.y += speed * delta
	if _wobble_amp > 0.0:
		_wobble_phase += delta * 2.0
		position.x += sin(_wobble_phase) * _wobble_amp * delta
	if position.y > 1040.0:
		queue_free()


func setup(p_speed: float, lane_x: float, start_y: float = -70.0) -> void:
	speed = p_speed
	position = Vector2(lane_x, start_y)
