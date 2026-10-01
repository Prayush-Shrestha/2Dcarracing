extends Control
## Settings: music/SFX volumes, controls reference, reset progress
## with confirmation. Saved permanently via SaveManager.

var _save: Dictionary = {}
var _confirming: bool = false

@onready var back_button: Button = $Top/BackButton
@onready var music_slider: HSlider = $Scroll/Rows/MusicRow/MusicSlider
@onready var music_value: Label = $Scroll/Rows/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $Scroll/Rows/SfxRow/SfxSlider
@onready var sfx_value: Label = $Scroll/Rows/SfxRow/SfxValue
@onready var mute_check: CheckButton = $Scroll/Rows/MuteCheck
@onready var reset_button: Button = $Scroll/Rows/ResetButton
@onready var confirm_box: VBoxContainer = $Scroll/Rows/ConfirmBox
@onready var confirm_yes: Button = $Scroll/Rows/ConfirmBox/ConfirmRow/YesButton
@onready var confirm_no: Button = $Scroll/Rows/ConfirmBox/ConfirmRow/NoButton
@onready var click_player: AudioStreamPlayer = $ClickPlayer


func _ready() -> void:
	_save = SaveManager.load_data()
	back_button.pressed.connect(_on_back)
	music_slider.value_changed.connect(_on_music)
	sfx_slider.value_changed.connect(_on_sfx)
	mute_check.toggled.connect(_on_mute)
	reset_button.pressed.connect(_on_reset_pressed)
	confirm_yes.pressed.connect(_on_reset_confirmed)
	confirm_no.pressed.connect(_on_reset_cancelled)
	music_slider.value = float(_save.get("music_volume", 0.8)) * 100.0
	sfx_slider.value = float(_save.get("sfx_volume", 0.9)) * 100.0
	mute_check.set_pressed_no_signal(bool(_save.get("muted", false)))
	confirm_box.hide()
	_refresh_labels()
	_fade_in()


func _refresh_labels() -> void:
	music_value.text = "%d%%" % int(music_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)


func _apply_audio() -> void:
	AudioManager.apply_volumes(float(_save.get("music_volume", 0.8)), float(_save.get("sfx_volume", 0.9)), bool(_save.get("muted", false)))


func _on_music(v: float) -> void:
	_save["music_volume"] = clampf(v / 100.0, 0.0, 1.0)
	SaveManager.save_data(_save)
	_apply_audio()
	_refresh_labels()


func _on_sfx(v: float) -> void:
	_save["sfx_volume"] = clampf(v / 100.0, 0.0, 1.0)
	SaveManager.save_data(_save)
	_apply_audio()
	_refresh_labels()
	_click()


func _on_mute(on: bool) -> void:
	_save["muted"] = on
	SaveManager.save_data(_save)
	_apply_audio()
	_click()


func _on_reset_pressed() -> void:
	_click()
	confirm_box.show()
	confirm_yes.grab_focus()


func _on_reset_cancelled() -> void:
	_click()
	confirm_box.hide()
	reset_button.grab_focus()


func _on_reset_confirmed() -> void:
	SaveManager.reset_progress()
	_save = SaveManager.load_data()
	music_slider.set_value_no_signal(float(_save.get("music_volume", 0.8)) * 100.0)
	sfx_slider.set_value_no_signal(float(_save.get("sfx_volume", 0.9)) * 100.0)
	mute_check.set_pressed_no_signal(bool(_save.get("muted", false)))
	_apply_audio()
	_refresh_labels()
	confirm_box.hide()
	_click()


func _on_back() -> void:
	_click()
	get_tree().change_scene_to_file(GameManager.SCENE_MAIN_MENU)


func _click() -> void:
	AudioManager.play(click_player, "click", bool(_save.get("muted", false)))


func _fade_in() -> void:
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
