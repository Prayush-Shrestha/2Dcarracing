extends Control
## TRACKS screen: 7 environment themes (ROCK → SPACE).
## Each card shows a road preview strip, name, tagline, handling +
## hazard chips, and two actions: SELECT (save preference) and
## RACE (start a run immediately with this environment via
## GameManager.start_theme_run). Level runs without an override
## keep using their own level theme.
## New themes appear automatically from ThemeManager.THEMES.

var _save: Dictionary = {}
var _selected: int = 0
var _select_buttons: Array[Button] = []
var _cards_box: VBoxContainer = null

@onready var back_button: Button = $Top/BackButton
@onready var click_player: AudioStreamPlayer = $ClickPlayer


func _ready() -> void:
	_save = SaveManager.load_data()
	_selected = clampi(int(_save.get("selected_track", 0)), 0, ThemeManager.COUNT - 1)
	_cards_box = $Scroll/Cards
	back_button.pressed.connect(_on_back)
	await _rebuild_cards()
	_refresh()
	_fade_in()


func _rebuild_cards() -> void:
	_select_buttons.clear()
	for child in _cards_box.get_children():
		child.queue_free()
	await get_tree().process_frame
	for i in range(ThemeManager.count()):
		_cards_box.add_child(_make_card(i))


func _make_card(idx: int) -> PanelContainer:
	var t: Dictionary = ThemeManager.get_by_index(idx)
	var accent: Color = t.get("accent", Color(1, 0.81, 0.2))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Subtle AAA style: dark card handled by default theme; accent bar sells it.
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	card.add_child(outer)
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(0, 4)
	bar.color = accent
	outer.add_child(bar)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 5)
	margin.add_child(rows)
	# Preview: side | road with accent edges | side — mirrors real road colors.
	var preview := HBoxContainer.new()
	preview.add_theme_constant_override("separation", 0)
	rows.add_child(preview)
	var side_col: Color = t.get("side", Color.GRAY)
	var road_col: Color = t.get("road", Color.DARK_GRAY)
	var parts: Array[Color] = [side_col, accent, road_col, accent, side_col]
	var weights: Array[float] = [1.0, 0.12, 2.2, 0.12, 1.0]
	for k in range(parts.size()):
		var part := ColorRect.new()
		part.custom_minimum_size = Vector2(0, 30)
		part.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		part.size_flags_stretch_ratio = weights[k]
		part.color = parts[k]
		preview.add_child(part)
	# Title row: index badge + name + tagline.
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 22)
	title.text = "%d  %s" % [idx + 1, str(t.get("name", "THEME"))]
	rows.add_child(title)
	var tag := Label.new()
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", accent)
	tag.text = str(t.get("tagline", ""))
	rows.add_child(tag)
	var desc := Label.new()
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.72, 0.75, 0.79))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.text = str(t.get("desc", ""))
	rows.add_child(desc)
	var chips := Label.new()
	chips.add_theme_font_size_override("font_size", 13)
	chips.add_theme_color_override("font_color", Color(0.60, 0.63, 0.67))
	chips.text = "GRIP: %s   •   %s" % [str(t.get("handling_label", "")), str(t.get("hazard", ""))]
	rows.add_child(chips)
	# Actions: SELECT (preference) + RACE (play now with this environment).
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	rows.add_child(actions)
	var sel := Button.new()
	sel.add_theme_font_size_override("font_size", 16)
	sel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sidx := idx
	sel.pressed.connect(_on_select.bind(sidx))
	actions.add_child(sel)
	_select_buttons.append(sel)
	var race := Button.new()
	race.text = "RACE >"
	race.add_theme_font_size_override("font_size", 16)
	race.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ridx := idx
	race.pressed.connect(_on_race.bind(ridx))
	actions.add_child(race)
	return card


func _refresh() -> void:
	for i in range(_select_buttons.size()):
		_select_buttons[i].text = "SELECTED" if _selected == i else "SELECT"
		_select_buttons[i].disabled = _selected == i


func _on_select(idx: int) -> void:
	_selected = clampi(idx, 0, ThemeManager.COUNT - 1)
	_save["selected_track"] = _selected
	SaveManager.save_data(_save)
	_click()
	_refresh()


func _on_race(idx: int) -> void:
	var t: Dictionary = ThemeManager.get_by_index(idx)
	_selected = idx
	_save["selected_track"] = idx
	SaveManager.save_data(_save)
	_click()
	GameManager.start_theme_run(get_tree(), str(t.get("id", "rock_mountain")))


func _on_back() -> void:
	_click()
	get_tree().change_scene_to_file(GameManager.SCENE_MAIN_MENU)


func _click() -> void:
	AudioManager.play(click_player, "click", bool(_save.get("muted", false)))


func _fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
