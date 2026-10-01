extends Control
## Game over: score, distance, coins earned this run, level.
## RESTART retries the same level, LEVELS opens Level Select.

var _save: Dictionary = {}

@onready var score_label: Label = $Center/Box/ScoreLabel
@onready var coins_label: Label = $Center/Box/CoinsLabel
@onready var high_label: Label = $Center/Box/HighLabel
@onready var level_label: Label = $Center/Box/LevelLabel
@onready var distance_label: Label = $Center/Box/DistanceLabel
@onready var new_best_label: Label = $Center/Box/NewBestLabel
@onready var restart_button: Button = $Center/Box/RestartButton
@onready var menu_button: Button = $Center/Box/MenuButton
@onready var over_player: AudioStreamPlayer = $OverPlayer

var _levels_button: Button = null


func _ready() -> void:
	_save = SaveManager.load_data()
	var last_score := int(_save.get("last_score", GameManager.last_score))
	var last_coins := int(_save.get("last_coins", GameManager.last_coins))
	var last_level := maxi(1, int(_save.get("last_level", GameManager.pending_level)))
	var last_distance := float(_save.get("last_distance", GameManager.last_distance))
	var high := int(_save.get("high_score", last_score))
	AudioManager.apply_volumes(float(_save.get("music_volume", 0.8)), float(_save.get("sfx_volume", 0.9)), bool(_save.get("muted", false)))

	score_label.text = "SCORE: %d" % last_score
	coins_label.text = "COINS EARNED: %d" % last_coins
	high_label.text = "HIGH SCORE: %d" % high
	level_label.text = "LEVEL %d/10" % mini(last_level, 10)
	if distance_label != null:
		var target := float(LevelManager.get_level(last_level).get("distance", 0.0))
		distance_label.text = "DISTANCE: %dm / %dm" % [int(last_distance), int(target)]
	new_best_label.visible = last_score >= high and last_score > 0

	_ensure_levels_button()
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)
	_levels_button.pressed.connect(_on_levels)
	restart_button.grab_focus()
	AudioManager.play(over_player, "gameover", bool(_save.get("muted", false)))
	_fade_in()


func _ensure_levels_button() -> void:
	var box: VBoxContainer = $Center/Box
	if has_node("Center/Box/LevelsButton"):
		_levels_button = $Center/Box/LevelsButton
		return
	_levels_button = Button.new()
	_levels_button.name = "LevelsButton"
	_levels_button.text = "LEVEL SELECT"
	_levels_button.custom_minimum_size = Vector2(250, 46)
	_levels_button.add_theme_font_size_override("font_size", 18)
	box.add_child(_levels_button)
	box.move_child(_levels_button, box.get_child_count() - 1)


func _on_restart() -> void:
	get_tree().paused = false
	GameManager.start_level(get_tree(), maxi(1, int(_save.get("last_level", GameManager.pending_level))))


func _on_levels() -> void:
	get_tree().paused = false
	GameManager.to_levels(get_tree())


func _on_menu() -> void:
	get_tree().paused = false
	GameManager.to_menu(get_tree())


func _fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
