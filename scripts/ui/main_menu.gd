extends Control
## Main menu: PLAY, GARAGE, LEVELS, TRACKS, SETTINGS, QUIT.
## Shows high score + coins, subtle animated road background.

var _save: Dictionary = {}
var _road_offset: float = 0.0
var _dashes: Array[ColorRect] = []

@onready var play_button: Button = $Center/Menu/PlayButton
@onready var levels_button: Button = $Center/Menu/LevelsButton
@onready var garage_button: Button = $Center/Menu/GarageButton
@onready var tracks_button: Button = $Center/Menu/TracksButton
@onready var settings_button: Button = $Center/Menu/SettingsButton
@onready var quit_button: Button = $Center/Menu/QuitButton
@onready var best_label: Label = $Center/Menu/BestLabel
@onready var coins_label: Label = $Center/Menu/CoinsLabel
@onready var progress_label: Label = $Center/Menu/ProgressLabel
@onready var deco: ColorRect = $RoadDeco
@onready var click_player: AudioStreamPlayer = $ClickPlayer


func _ready() -> void:
	_save = SaveManager.load_data()
	AudioManager.apply_volumes(float(_save.get("music_volume", 0.8)), float(_save.get("sfx_volume", 0.9)), bool(_save.get("muted", false)))
	play_button.pressed.connect(_on_play)
	if levels_button != null:
		levels_button.pressed.connect(_on_levels)
	garage_button.pressed.connect(_on_garage)
	tracks_button.pressed.connect(_on_tracks)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	play_button.grab_focus()
	_build_animated_dashes()
	_refresh_stats()
	_fade_in()
	_add_hover(play_button)
	_add_hover(levels_button)
	_add_hover(garage_button)
	_add_hover(tracks_button)
	_add_hover(settings_button)
	_add_hover(quit_button)


func _process(delta: float) -> void:
	_road_offset = fmod(_road_offset + delta * 160.0, 80.0)
	for i in range(_dashes.size()):
		var d: ColorRect = _dashes[i]
		d.position.y = -40.0 + float(i % 12) * 80.0 + _road_offset


func _build_animated_dashes() -> void:
	for child in get_children():
		if child.name.begins_with("MenuDash"):
			child.queue_free()
	for i in range(12):
		var d := ColorRect.new()
		d.name = "MenuDash%d" % i
		d.color = Color(0.9, 0.9, 0.88, 0.25)
		d.size = Vector2(6, 34)
		d.position = Vector2(267, -40.0 + float(i) * 80.0)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		move_child(d, 1)
		_dashes.append(d)


func _refresh_stats() -> void:
	best_label.text = "HIGH SCORE: %d" % int(_save.get("high_score", 0))
	coins_label.text = "COINS: %d" % int(_save.get("coins", 0))
	var completed: Array = _save.get("completed_levels", [])
	if progress_label != null:
		progress_label.text = "PROGRESS: %d/10 LEVELS" % completed.size()


func _on_play() -> void:
	_click()
	GameManager.quick_play(get_tree())


func _on_levels() -> void:
	_click()
	GameManager.to_levels(get_tree())


func _on_garage() -> void:
	_click()
	get_tree().change_scene_to_file(GameManager.SCENE_GARAGE)


func _on_tracks() -> void:
	_click()
	get_tree().change_scene_to_file(GameManager.SCENE_TRACKS)


func _on_settings() -> void:
	_click()
	get_tree().change_scene_to_file(GameManager.SCENE_SETTINGS)


func _on_quit() -> void:
	_click()
	get_tree().quit()


func _click() -> void:
	AudioManager.play(click_player, "click", bool(_save.get("muted", false)))


func _fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)


func _add_hover(btn: Button) -> void:
	if btn == null:
		return
	btn.mouse_entered.connect(func() -> void: btn.modulate = Color(1.05, 1.05, 1.0))
	btn.mouse_exited.connect(func() -> void: btn.modulate = Color.WHITE)
