extends Control
## Main menu: Play, Garage, Settings, Quit. Shows best score and coin total.

const SAVE_PATH := "user://street_rush_save.cfg"

@onready var play_button: Button = $Center/Menu/PlayButton
@onready var garage_button: Button = $Center/Menu/GarageButton
@onready var tracks_button: Button = $Center/Menu/TracksButton
@onready var settings_button: Button = $Center/Menu/SettingsButton
@onready var quit_button: Button = $Center/Menu/QuitButton
@onready var best_label: Label = $Center/Menu/BestLabel
@onready var coins_label: Label = $Center/Menu/CoinsLabel
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var mute_check: CheckButton = $SettingsPanel/Margin/Rows/MuteCheck
@onready var reset_button: Button = $SettingsPanel/Margin/Rows/ResetButton
@onready var close_button: Button = $SettingsPanel/Margin/Rows/CloseButton
@onready var click_player: AudioStreamPlayer = $ClickPlayer


func _ready() -> void:
	play_button.pressed.connect(_on_play)
	garage_button.pressed.connect(_on_garage)
	tracks_button.pressed.connect(_on_tracks)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	mute_check.toggled.connect(_on_mute)
	reset_button.pressed.connect(_on_reset)
	close_button.pressed.connect(_on_close_settings)
	play_button.grab_focus()
	settings_panel.hide()
	_refresh_stats()


func _refresh_stats() -> void:
	var cfg := ConfigFile.new()
	var best := 0
	var coins := 0
	var muted := false
	if cfg.load(SAVE_PATH) == OK:
		best = int(cfg.get_value("save", "high_score", 0))
		coins = int(cfg.get_value("save", "total_coins", 0))
		muted = bool(cfg.get_value("save", "muted", false))
	best_label.text = "HIGH SCORE: %d" % best
	coins_label.text = "COINS: %d" % coins
	mute_check.set_pressed_no_signal(muted)
	AudioServer.set_bus_mute(0, muted)


func _on_play() -> void:
	_click()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_garage() -> void:
	_click()
	get_tree().change_scene_to_file("res://scenes/Garage.tscn")


func _on_tracks() -> void:
	_click()
	get_tree().change_scene_to_file("res://scenes/Themes.tscn")


func _on_settings() -> void:
	_click()
	settings_panel.show()


func _on_close_settings() -> void:
	_click()
	settings_panel.hide()


func _on_quit() -> void:
	_click()
	get_tree().quit()


func _on_mute(on: bool) -> void:
	AudioServer.set_bus_mute(0, on)
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("save", "muted", on)
	cfg.save(SAVE_PATH)
	_click()


func _on_reset() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "high_score", 0)
	cfg.set_value("save", "total_coins", 0)
	cfg.set_value("save", "best_level", 1)
	cfg.set_value("save", "theme", 0)
	cfg.set_value("save", "unlocked", [0])
	cfg.set_value("save", "selected", 0)
	cfg.set_value("save", "last_score", 0)
	cfg.set_value("save", "last_coins", 0)
	cfg.set_value("save", "last_level", 1)
	cfg.save(SAVE_PATH)
	_refresh_stats()
	_click()


func _click() -> void:
	var muted := AudioServer.is_bus_mute(0)
	if muted:
		return
	if FileAccess.file_exists("res://assets/sounds/click.wav"):
		var s := load("res://assets/sounds/click.wav")
		if s is AudioStream:
			click_player.stream = s
			click_player.play()
			return
	click_player.stream = _tone(660.0, 0.07)
	click_player.play()


func _tone(freq: float, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * dur)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var t := float(i) / float(rate)
		data[i] = int(128.0 + 80.0 * sin(TAU * freq * t))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
