extends Node2D
## Endless scrolling road.
## Builds lane dashes in code and moves them down every frame.
## Game.gd sets road_speed to control difficulty.

var road_speed: float = 420.0
var scrolling: bool = true

var road_left: float = 90.0
var road_right: float = 450.0
var lanes: Array[float] = [135.0, 225.0, 315.0, 405.0]

var _dashes: Array[ColorRect] = []

@onready var dashes_root: Node2D = $Dashes


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
	# 3 dividers between the 4 lanes.
	var divider_x: Array[float] = [180.0, 270.0, 360.0]
	var dash_h := 44.0
	var gap := 116.0
	for x in divider_x:
		for i in range(7):
			var r := ColorRect.new()
			r.color = Color(0.9, 0.9, 0.88, 0.95)
			r.size = Vector2(6, dash_h)
			r.position = Vector2(x - 3.0, -80.0 + float(i) * (dash_h + gap))
			dashes_root.add_child(r)
			_dashes.append(r)


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
