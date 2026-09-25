extends Control
## Track theme picker: Highway, Desert, Ice, Night. Saves the selection,
## Game.gd applies it to the road when a run starts.

const SAVE_PATH := "user://street_rush_save.cfg"

# Must match the THEMES list in game.gd (name/desc/preview colors).
const THEMES: Array[Dictionary] = [
	{
		"name": "HIGHWAY", "desc": "Classic daylight highway.",
		"side": Color(0.14, 0.32, 0.18), "road": Color(0.17, 0.18, 0.20),
	},
	{
		"name": "DESERT", "desc": "Hot sand, red-line road.",
		"side": Color(0.82, 0.71, 0.51), "road": Color(0.33, 0.32, 0.31),
	},
	{
		"name": "ICE", "desc": "Frozen track. Slippery!",
		"side": Color(0.74, 0.84, 0.91), "road": Color(0.30, 0.36, 0.44),
	},
	{
		"name": "NIGHT", "desc": "Night drive. Amber lines.",
		"side": Color(0.05, 0.07, 0.10), "road": Color(0.10, 0.11, 0.13),
	},
]

var selected: int = 0

@onready var back_button: Button = $Top/BackButton
@onready var card0: PanelContainer = $Cards/Card0
@onready var card1: PanelContainer = $Cards/Card1
@onready var card2: PanelContainer = $Cards/Card2
@onready var card3: PanelContainer = $Cards/Card3
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var cards: Array = []


func _ready() -> void:
	cards = [card0, card1, card2, card3]
	_load()
	back_button.pressed.connect(_on_back)
	for i in range(cards.size()):
		var btn: Button = cards[i].get_node("Margin/Rows/ActionButton")
		var idx := i
		btn.pressed.connect(_on_select.bind(idx))
	_refresh()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	selected = clampi(int(cfg.get_value("save", "theme", 0)), 0, THEMES.size() - 1)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("save", "theme", selected)
	cfg.save(SAVE_PATH)


func _refresh() -> void:
	for i in range(cards.size()):
		var theme := THEMES[i]
		var name_l: Label = cards[i].get_node("Margin/Rows/NameLabel")
		var desc_l: Label = cards[i].get_node("Margin/Rows/DescLabel")
		var btn: Button = cards[i].get_node("Margin/Rows/ActionButton")
		var side_prev: ColorRect = cards[i].get_node("Margin/Rows/Preview/Side")
		var road_prev: ColorRect = cards[i].get_node("Margin/Rows/Preview/Road")
		name_l.text = theme["name"]
		desc_l.text = theme["desc"]
		side_prev.color = theme["side"]
		road_prev.color = theme["road"]
		btn.text = "SELECTED" if selected == i else "SELECT"
		btn.disabled = selected == i


func _on_select(idx: int) -> void:
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
