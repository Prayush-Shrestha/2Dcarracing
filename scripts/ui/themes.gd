extends Control
## Track theme picker: HIGHWAY, DESERT, ICE, NIGHT, RAIN.
## Saves the free-drive preference. Level runs use their own theme.

const TRACKS: Array[Dictionary] = [
	{"name": "HIGHWAY", "desc": "Classic daylight highway.", "handling": "Normal grip"},
	{"name": "DESERT", "desc": "Hot sand, red-line road.", "handling": "Normal grip"},
	{"name": "ICE", "desc": "Frozen track. Slippery!", "handling": "Low grip"},
	{"name": "NIGHT", "desc": "Night drive. Amber lines.", "handling": "Normal grip"},
	{"name": "RAIN", "desc": "Wet road, rain particles.", "handling": "Slightly loose"},
]

var _save: Dictionary = {}
var _selected: int = 0
var _buttons: Array[Button] = []

@onready var back_button: Button = $Top/BackButton
@onready var cards_box: VBoxContainer = $Cards
@onready var click_player: AudioStreamPlayer = $ClickPlayer


func _ready() -> void:
	_save = SaveManager.load_data()
	_selected = clampi(int(_save.get("selected_track", 0)), 0, 4)
	back_button.pressed.connect(_on_back)
	await _rebuild_cards()
	_refresh()
	_fade_in()


func _rebuild_cards() -> void:
	_buttons.clear()
	for child in cards_box.get_children():
		child.queue_free()
	await get_tree().process_frame
	for i in range(TRACKS.size()):
		var preview_colors := _preview_colors(i)
		var card := PanelContainer.new()
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)
		var rows := VBoxContainer.new()
		rows.add_theme_constant_override("separation", 4)
		margin.add_child(rows)
		var preview := HBoxContainer.new()
		preview.add_theme_constant_override("separation", 0)
		rows.add_child(preview)
		for k in range(3):
			var part := ColorRect.new()
			part.custom_minimum_size = Vector2(0, 26)
			part.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			part.color = preview_colors["side"] if k != 1 else preview_colors["road"]
			preview.add_child(part)
		var name_l := Label.new()
		name_l.add_theme_font_size_override("font_size", 22)
		name_l.text = TRACKS[i]["name"]
		rows.add_child(name_l)
		var desc_l := Label.new()
		desc_l.add_theme_font_size_override("font_size", 14)
		desc_l.add_theme_color_override("font_color", Color(0.6, 0.63, 0.67))
		desc_l.text = "%s (%s)" % [TRACKS[i]["desc"], TRACKS[i]["handling"]]
		rows.add_child(desc_l)
		var btn := Button.new()
		btn.add_theme_font_size_override("font_size", 17)
		var idx := i
		btn.pressed.connect(_on_select.bind(idx))
		rows.add_child(btn)
		cards_box.add_child(card)
		_buttons.append(btn)


func _preview_colors(idx: int) -> Dictionary:
	match idx:
		0:
			return {"side": Color(0.14, 0.32, 0.18), "road": Color(0.17, 0.18, 0.20)}
		1:
			return {"side": Color(0.82, 0.71, 0.51), "road": Color(0.33, 0.32, 0.31)}
		2:
			return {"side": Color(0.74, 0.84, 0.91), "road": Color(0.30, 0.36, 0.44)}
		3:
			return {"side": Color(0.05, 0.07, 0.10), "road": Color(0.10, 0.11, 0.13)}
		_:
			return {"side": Color(0.16, 0.22, 0.18), "road": Color(0.19, 0.22, 0.26)}


func _refresh() -> void:
	for i in range(_buttons.size()):
		_buttons[i].text = "SELECTED" if _selected == i else "SELECT"
		_buttons[i].disabled = _selected == i


func _on_select(idx: int) -> void:
	_selected = idx
	_save["selected_track"] = idx
	SaveManager.save_data(_save)
	_click()
	_refresh()


func _on_back() -> void:
	_click()
	get_tree().change_scene_to_file(GameManager.SCENE_MAIN_MENU)


func _click() -> void:
	AudioManager.play(click_player, "click", bool(_save.get("muted", false)))


func _fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
