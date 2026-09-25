extends Control
## Victory screen. Shown after beating all 10 levels.

const SAVE_PATH := "user://street_rush_save.cfg"
const MAX_LEVEL := 10

@onready var score_label: Label = $Center/Box/ScoreLabel
@onready var coins_label: Label = $Center/Box/CoinsLabel
@onready var high_label: Label = $Center/Box/HighLabel
@onready var again_button: Button = $Center/Box/AgainButton
@onready var menu_button: Button = $Center/Box/MenuButton
@onready var win_player: AudioStreamPlayer = $WinPlayer


func _ready() -> void:
	var last_score := 0
	var last_coins := 0
	var high := 0
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		last_score = int(cfg.get_value("save", "last_score", 0))
		last_coins = int(cfg.get_value("save", "last_coins", 0))
		high = int(cfg.get_value("save", "high_score", last_score))

	score_label.text = "FINAL SCORE: %d" % last_score
	coins_label.text = "COINS: %d" % last_coins
	high_label.text = "HIGH SCORE: %d" % high

	again_button.pressed.connect(_on_again)
	menu_button.pressed.connect(_on_menu)
	again_button.grab_focus()
	_play_win()


func _on_again() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _play_win() -> void:
	if AudioServer.is_bus_mute(0):
		return
	if FileAccess.file_exists("res://assets/sounds/victory.wav"):
		var s := load("res://assets/sounds/victory.wav")
		if s is AudioStream:
			win_player.stream = s
			win_player.play()
			return
	var rate := 22050
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
	var total := 0.9
	var frames := int(rate * total)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var t := float(i) / float(rate)
		var k := int(t / 0.16)
		var f: float = notes[mini(k, notes.size() - 1)]
		var env := exp(-3.0 * (t - float(k) * 0.16) / 0.16)
		data[i] = int(128.0 + 80.0 * env * sin(TAU * f * t))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	win_player.stream = stream
	win_player.play()
