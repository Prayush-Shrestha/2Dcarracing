extends Area2D
## Falling power-up pickup. Either SHIELD (blocks one crash) or
## MAGNET (pulls coins for PowerUpDef.MAGNET_DURATION seconds).

signal picked(kind: String, at: Vector2)

var kind: String = "shield"
var fall_speed: float = 420.0
var _taken: bool = false
var _bob: float = 0.0

@onready var visuals: Node2D = $Visuals
@onready var outer: Polygon2D = $Visuals/Outer
@onready var glyph: Label = $Visuals/Glyph


func _ready() -> void:
	add_to_group("powerup")
	_bob = randf() * TAU
	area_entered.connect(_on_area_entered)
	_refresh_visuals()


func setup(p_kind: String, p_fall: float) -> void:
	kind = p_kind
	fall_speed = p_fall
	if is_node_ready():
		_refresh_visuals()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	position.y += fall_speed * delta
	_bob += delta * 4.0
	if visuals != null:
		visuals.position.y = sin(_bob) * 4.0
	if position.y > 1020.0:
		queue_free()


func _refresh_visuals() -> void:
	if outer != null:
		outer.color = PowerUpDef.color_for(kind)
	if glyph != null:
		glyph.text = "S" if kind == PowerUpDef.KIND_SHIELD else "M"


func _on_area_entered(area: Area2D) -> void:
	if _taken:
		return
	if area.is_in_group("player"):
		_taken = true
		picked.emit(kind, global_position)
		queue_free()
