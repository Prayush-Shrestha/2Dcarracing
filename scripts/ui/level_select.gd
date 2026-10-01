extends Control
## Level Select: all 10 levels with completed / unlocked / locked state.
## Locked levels cannot be started. Completing a level unlocks the next.

var _save: Dictionary = {}
var _cards_box: VBoxContainer = null

@onready var back_button: Button = $Top/BackButton
@onready var coins_label: Label = $Top/CoinsLabel
@onready var cards: VBoxContainer = $Scroll/Cards
@onready var click_player: AudioStreamPlayer = $ClickPlayer


func _ready() -> void:
	_save = SaveManager.load_data()
	back_button.pressed.connect(_on_back)
	_refresh()
	_fade_in()


func _refresh() -> void:
	coins_label.text = "COINS: %d" % int(_save.get("coins", 0))
	for child in cards.get_children():
		child.queue_free()
	await get_tree().process_frame
	var completed: Array = _save.get("completed_levels", [])
	var unlocked: Array = _save.get("unlocked_levels", [1])
	for i in range(1, LevelManager.MAX_LEVEL + 1):
		cards.add_child(_make_card(i, completed, unlocked))


func _make_card(number: int, completed: Array, unlocked: Array) -> PanelContainer:
	var def := LevelManager.get_level(number)
	var card := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	margin.add_child(rows)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 20)
	var state := "LOCKED"
	if completed.has(number):
		state = "✓ COMPLETED"
	elif unlocked.has(number):
		state = "UNLOCKED"
	title.text = "LEVEL %d — %s  [%s]" % [number, str(def.get("name", "")), state]
	if state == "LOCKED":
		title.add_theme_color_override("font_color", Color(0.55, 0.58, 0.62))
	elif state.begins_with("✓"):
		title.add_theme_color_override("font_color", Color(0.5, 0.9, 0.55))
	else:
		title.add_theme_color_override("font_color", Color(1.0, 0.81, 0.2))
	rows.add_child(title)
	var info := Label.new()
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "%s  •  %s  •  %dm  •  Reward %d coins  •  %s" % [
		str(def.get("theme", "")), str(def.get("difficulty", "")),
		int(def.get("distance", 0)), int(def.get("reward", 0)), str(def.get("desc", ""))]
	rows.add_child(info)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 17)
	if completed.has(number):
		btn.text = "REPLAY"
	elif unlocked.has(number):
		btn.text = "START — %dm" % int(def.get("distance", 0))
	else:
		btn.text = "LOCKED — CLEAR LEVEL %d" % maxi(number - 1, 1)
		btn.disabled = true
	btn.pressed.connect(_on_start.bind(number, btn))
	rows.add_child(btn)
	return card


func _on_start(number: int, _btn: Button) -> void:
	var unlocked: Array = _save.get("unlocked_levels", [1])
	if not unlocked.has(number):
		return
	_click()
	GameManager.start_level(get_tree(), number)


func _on_back() -> void:
	_click()
	get_tree().change_scene_to_file(GameManager.SCENE_MAIN_MENU)


func _click() -> void:
	AudioManager.play(click_player, "click", bool(_save.get("muted", false)))


func _fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
