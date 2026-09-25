extends Control
## Game over screen. Reads the last run that Game.gd saved, offers restart/menu.

const SAVE_PATH := "user://street_rush_save.cfg"

@onready var score_label: Label = $Center/Box/ScoreLabel
@onready var coins_label: Label = $Center/Box/CoinsLabel
@onready var high_label: Label = $Center/Box/HighLabel
@onready var level_label: Label = $Center/Box/LevelLabel
@onready var new_best_label: Label = $Center/Box/NewBestLabel
@onready var restart_button: Button = $Center/Box/RestartButton
@onready var menu_button: Button = $Center/Box/MenuButton
@onready var over_player: AudioStreamPlayer = $OverPlayer


func _ready() -> void:
	var last_score := 0
	var last_coins := 0
	var last_level := 1
	var high := 0
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		last_score = int(cfg.get_value("save", "last_score", 0))
		last_coins = int(cfg.get_value("save", "last_coins", 0))
		last_level = maxi(1, int(cfg.get_value("save", "last_level", 1)))
		high = int(cfg.get_value("save", "high_score", last_score))

	score_label.text = "FINAL SCORE: %d" % last_score
	coins_label.text = "COINS: %d" % last_coins
	high_label.text = "HIGH SCORE: %d" % high
	level_label.text = "REACHED LEVEL %d/10" % mini(last_level, 10)
	new_best_label.visible = last_score >= high and last_score > 0

	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)
	restart_button.grab_focus()
	_play_game_over()


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _play_game_over() -> void:
	if AudioServer.is_bus_mute(0):
		return
	if FileAccess.file_exists("res://assets/sounds/gameover.wav"):
		var s := load("res://assets/sounds/gameover.wav")
		if s is AudioStream:
			over_player.stream = s
			over_player.play()
			return
	var rate := 22050
	var frames := int(rate * 0.5)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var t := float(i) / float(rate)
		var k := float(i) / float(frames)
		data[i] = int(128.0 + 80.0 * (1.0 - k) * sin(TAU * lerpf(320.0, 110.0, k) * t))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	over_player.stream = stream
	over_player.play()
