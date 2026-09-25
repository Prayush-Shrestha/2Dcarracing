extends Control
## Garage: 3 cars with stats, unlock with coins, select to race.

const SAVE_PATH := "user://street_rush_save.cfg"

const CARS: Array[Dictionary] = [
	{
		"name": "STARTER", "cost": 0, "speed": 60.0, "accel": 60.0,
		"handling": 80.0, "color": Color(0.18, 0.55, 1.0),
		"desc": "Balanced and easy to drive."
	},
	{
		"name": "SPORT", "cost": 500, "speed": 80.0, "accel": 75.0,
		"handling": 70.0, "color": Color(0.85, 0.2, 0.22),
		"desc": "Faster, a bit twitchy."
	},
	{
		"name": "SUPER", "cost": 1500, "speed": 95.0, "accel": 90.0,
		"handling": 60.0, "color": Color(0.95, 0.75, 0.2),
		"desc": "Very fast. Needs control."
	},
]

var total_coins: int = 0
var unlocked: Array = [0]
var selected: int = 0

@onready var coins_label: Label = $Top/CoinsLabel
@onready var back_button: Button = $Top/BackButton
@onready var card0: PanelContainer = $Cards/Card0
@onready var card1: PanelContainer = $Cards/Card1
@onready var card2: PanelContainer = $Cards/Card2
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var cards: Array = []


func _ready() -> void:
	cards = [card0, card1, card2]
	_load()
	back_button.pressed.connect(_on_back)
	for i in range(cards.size()):
		var btn: Button = cards[i].get_node("Margin/Rows/ActionButton")
		var idx := i
		btn.pressed.connect(_on_action.bind(idx))
	_refresh()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	total_coins = int(cfg.get_value("save", "total_coins", 0))
	selected = int(cfg.get_value("save", "selected", 0))
	var raw = cfg.get_value("save", "unlocked", [0])
	unlocked = []
	if raw is Array:
		for v in raw:
			unlocked.append(int(v))
	if unlocked.is_empty():
		unlocked = [0]


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("save", "total_coins", total_coins)
	cfg.set_value("save", "unlocked", unlocked)
	cfg.set_value("save", "selected", selected)
	cfg.save(SAVE_PATH)


func _refresh() -> void:
	coins_label.text = "COINS: %d" % total_coins
	for i in range(cards.size()):
		var car := CARS[i]
		var name_l: Label = cards[i].get_node("Margin/Rows/NameLabel")
		var stat_l: Label = cards[i].get_node("Margin/Rows/StatLabel")
		var desc_l: Label = cards[i].get_node("Margin/Rows/DescLabel")
		var btn: Button = cards[i].get_node("Margin/Rows/ActionButton")
		var preview: ColorRect = cards[i].get_node("Margin/Rows/Preview")
		preview.color = car["color"]
		name_l.text = car["name"]
		stat_l.text = "Speed %d   Accel %d   Handling %d" % [int(car["speed"]), int(car["accel"]), int(car["handling"])]
		desc_l.text = car["desc"]
		if unlocked.has(i):
			btn.text = "SELECTED" if selected == i else "SELECT"
			btn.disabled = selected == i
		else:
			btn.text = "UNLOCK - %d" % int(car["cost"])
			btn.disabled = total_coins < int(car["cost"])


func _on_action(idx: int) -> void:
	if unlocked.has(idx):
		selected = idx
		_save()
		_click()
		_refresh()
		return
	var cost := int(CARS[idx]["cost"])
	if total_coins >= cost:
		total_coins -= cost
		unlocked.append(idx)
		selected = idx
		_save()
		_click()
	_refresh()


func _on_back() -> void:
	_click()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _click() -> void:
	if AudioServer.is_bus_mute(0):
		return
	if FileAccess.file_exists("res://assets/sounds/click.wav"):
		var s := load("res://assets/sounds/click.wav")
		if s is AudioStream:
			click_player.stream = s
			click_player.play()
			return
	var rate := 22050
	var frames := int(rate * 0.07)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		data[i] = int(128.0 + 80.0 * sin(TAU * 660.0 * float(i) / float(rate)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.data = data
	click_player.stream = stream
	click_player.play()
