extends Area2D
## Collectible coin. Falls with the road, spins, collects on player touch.

signal collected(coin: Area2D)

var fall_speed: float = 420.0
var value: int = 1
var score_bonus: int = 50

var _spin: float = 0.0
var _taken: bool = false

@onready var outer: Polygon2D = $Visuals/Outer
@onready var inner: Polygon2D = $Visuals/Inner
@onready var visuals: Node2D = $Visuals


func _ready() -> void:
	add_to_group("coin")
	_spin = randf() * TAU
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	position.y += fall_speed * delta
	_spin += delta * 5.0
	var squash := absf(cos(_spin))
	visuals.scale.x = 0.45 + 0.55 * squash
	if position.y > 1020.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _taken:
		return
	if area.is_in_group("player"):
		_taken = true
		collected.emit(self)
		queue_free()
