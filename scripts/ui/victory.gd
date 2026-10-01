extends Control
## Victory: STREET RUSH CHAMPIONSHIP COMPLETE with final score,
## distance, coins earned and total coins. PLAY AGAIN / LEVELS / MENU.

var _save: Dictionary = {}

@onready var score_label: Label = $Center/Box/ScoreLabel
@onready var coins_label: Label = $Center/Box/CoinsLabel
@onready var high_label: Label = $Center/Box/HighLabel
@onready var again_button: Button = $Center/Box/AgainButton
@onready var menu_button: Button = $Center/Box/MenuButton
@onready var win_player: AudioStreamPlayer = $WinPlayer

var _levels_button: Button = null
var _detail_label: Label = null


func _ready() -> void:
	_save = SaveManager.load_data()
	var last_score := int(_save.get("last_score", GameManager.last_score))
	var last_coins := int(_save.get("last_coins", GameManager.last_coins))
	var last_distance := float(_save.get("last_distance", GameManager.last_distance))
	var high := int(_save.get("high_score", last_score))
	var total := int(_save.get("coins", 0))
	AudioManager.apply_volumes(float(_save.get("music_volume", 0.8)), float(_save.get("sfx_volume", 0.9)), bool(_save.get("muted", false)))

	score_label.text = "FINAL SCORE: %d" % last_score
	coins_label.text = "COINS EARNED: %d" % last_coins
	high_label.text = "HIGH SCORE: %d   •   TOTAL COINS: %d" % [high, total]
	_ensure_detail_label()
	_detail_label.text = "LEVEL 10/10  •  DISTANCE %dm / 6000m" % int(last_distance)

	_ensure_levels_button()
	again_button.pressed.connect(_on_again)
	menu_button.pressed.connect(_on_menu)
	_levels_button.pressed.connect(_on_levels)
	again_button.grab_focus()
	AudioManager.play(win_player, "victory", bool(_save.get("muted", false)))
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


func _ensure_detail_label() -> void:
	var box: VBoxContainer = $Center/Box
	if has_node("Center/Box/DetailLabel"):
		_detail_label = $Center/Box/DetailLabel
		return
	_detail_label = Label.new()
	_detail_label.name = "DetailLabel"
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.add_theme_font_size_override("font_size", 18)
	_detail_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.78))
	box.add_child(_detail_label)
	box.move_child(_detail_label, 3)


func _on_again() -> void:
	get_tree().paused = false
	GameManager.start_level(get_tree(), 1)


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
