extends CanvasLayer
## Pause overlay: RESUME, RESTART, SETTINGS, LEVELS, MAIN MENU.
## Shown/hidden by game.gd. Works while the tree is paused.

signal resume_requested
signal restart_requested
signal menu_requested
signal levels_requested

@onready var resume_button: Button = $Center/Box/ResumeButton
@onready var restart_button: Button = $Center/Box/RestartButton
@onready var menu_button: Button = $Center/Box/MenuButton

var _settings_button: Button = null
var _levels_button: Button = null
var _settings_panel: PanelContainer = null
var _music_slider: HSlider = null
var _sfx_slider: HSlider = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_ensure_extra_buttons()
	_ensure_settings_panel()
	hide_pause()
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	_levels_button.pressed.connect(func() -> void: levels_requested.emit())
	_settings_button.pressed.connect(_toggle_settings)


func show_pause() -> void:
	show()
	if _settings_panel != null:
		_settings_panel.hide()
		_settings_button.text = "SETTINGS"
	resume_button.grab_focus()


func hide_pause() -> void:
	hide()


func _ensure_extra_buttons() -> void:
	var box: VBoxContainer = $Center/Box
	if not has_node("Center/Box/LevelsButton"):
		_levels_button = Button.new()
		_levels_button.name = "LevelsButton"
		_levels_button.text = "LEVELS"
		_levels_button.custom_minimum_size = Vector2(240, 46)
		_levels_button.add_theme_font_size_override("font_size", 19)
		box.add_child(_levels_button)
		box.move_child(_levels_button, 3)
	else:
		_levels_button = $Center/Box/LevelsButton
	if not has_node("Center/Box/SettingsButton"):
		_settings_button = Button.new()
		_settings_button.name = "SettingsButton"
		_settings_button.text = "SETTINGS"
		_settings_button.custom_minimum_size = Vector2(240, 46)
		_settings_button.add_theme_font_size_override("font_size", 19)
		box.add_child(_settings_button)
		box.move_child(_settings_button, 3)
	else:
		_settings_button = $Center/Box/SettingsButton


func _ensure_settings_panel() -> void:
	if has_node("SettingsPanel"):
		_settings_panel = $SettingsPanel
		return
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.position = Vector2(120, 300)
	_settings_panel.custom_minimum_size = Vector2(300, 0)
	add_child(_settings_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	_settings_panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)
	var title := Label.new()
	title.text = "QUICK SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	rows.add_child(title)
	var mlab := Label.new()
	mlab.text = "Music volume"
	rows.add_child(mlab)
	_music_slider = HSlider.new()
	_music_slider.max_value = 100.0
	rows.add_child(_music_slider)
	var slab := Label.new()
	slab.text = "SFX volume"
	rows.add_child(slab)
	_sfx_slider = HSlider.new()
	_sfx_slider.max_value = 100.0
	rows.add_child(_sfx_slider)
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	rows.add_child(close_btn)
	close_btn.pressed.connect(_toggle_settings)
	var data := SaveManager.load_data()
	_music_slider.value = float(data.get("music_volume", 0.8)) * 100.0
	_sfx_slider.value = float(data.get("sfx_volume", 0.9)) * 100.0
	_music_slider.value_changed.connect(_on_volumes)
	_sfx_slider.value_changed.connect(_on_volumes)
	_settings_panel.hide()


func _toggle_settings() -> void:
	if _settings_panel == null:
		return
	_settings_panel.visible = not _settings_panel.visible
	_settings_button.text = "CLOSE SETTINGS" if _settings_panel.visible else "SETTINGS"


func _on_volumes(_v: float) -> void:
	var data := SaveManager.load_data()
	data["music_volume"] = clampf(_music_slider.value / 100.0, 0.0, 1.0)
	data["sfx_volume"] = clampf(_sfx_slider.value / 100.0, 0.0, 1.0)
	SaveManager.save_data(data)
	AudioManager.apply_volumes(float(data["music_volume"]), float(data["sfx_volume"]), bool(data.get("muted", false)))
