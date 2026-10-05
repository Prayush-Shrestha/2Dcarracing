extends Control
## Garage: car preview, unlock/select, per-stat upgrades.
## Only sensible buttons are shown. All coins/upgrades persist.

var _save: Dictionary = {}

@onready var coins_label: Label = $Top/CoinsLabel
@onready var back_button: Button = $Top/BackButton
@onready var card0: PanelContainer = $Cards/Card0
@onready var card1: PanelContainer = $Cards/Card1
@onready var card2: PanelContainer = $Cards/Card2
@onready var card3: PanelContainer = $Cards/Card3
@onready var card4: PanelContainer = $Cards/Card4
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var _cards: Array = []


func _ready() -> void:
	_cards = [card0, card1, card2, card3, card4]
	_save = SaveManager.load_data()
	back_button.pressed.connect(_on_back)
	for i in range(_cards.size()):
		var btn: Button = _cards[i].get_node("Margin/Rows/ActionButton")
		var idx := i
		btn.pressed.connect(_on_action.bind(idx))
		_ensure_upgrade_rows(i)
	_refresh()
	_fade_in()


func _process(_delta: float) -> void:
	# Animate rainbow paint on previews so the card shows the real effect.
	for i in range(_cards.size()):
		if bool(CarUpgrade.base_car(i).get("rainbow", false)):
			var preview: ColorRect = _cards[i].get_node("Margin/Rows/Preview")
			preview.color = Color.from_hsv(fposmod(Time.get_ticks_msec() / 4000.0, 1.0), 0.85, 1.0)


func _ensure_upgrade_rows(idx: int) -> void:
	var rows: VBoxContainer = _cards[idx].get_node("Margin/Rows")
	for stat in ["speed", "accel", "handling"]:
		var row_name := "Upgrade_%s" % stat
		if rows.has_node(row_name):
			continue
		var row := HBoxContainer.new()
		row.name = row_name
		row.add_theme_constant_override("separation", 8)
		var lab := Label.new()
		lab.name = "Label"
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.add_theme_font_size_override("font_size", 14)
		row.add_child(lab)
		var btn := Button.new()
		btn.name = "Button"
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_upgrade.bind(idx, stat))
		row.add_child(btn)
		rows.add_child(row)
		rows.move_child(row, rows.get_child_count() - 2)


func _refresh() -> void:
	coins_label.text = "COINS: %d" % int(_save.get("coins", 0))
	var unlocked: Array = _save.get("unlocked_cars", [0])
	var selected := int(_save.get("selected_car", 0))
	for i in range(_cards.size()):
		var base := CarUpgrade.base_car(i)
		var upg := CarUpgrade.upgrades_for(_save, i)
		var eff := CarUpgrade.effective_stats(i, upg)
		var name_l: Label = _cards[i].get_node("Margin/Rows/NameLabel")
		var stat_l: Label = _cards[i].get_node("Margin/Rows/StatLabel")
		var desc_l: Label = _cards[i].get_node("Margin/Rows/DescLabel")
		var btn: Button = _cards[i].get_node("Margin/Rows/ActionButton")
		var preview: ColorRect = _cards[i].get_node("Margin/Rows/Preview")
		preview.color = eff["color"]
		var tag := ""
		if selected == i and unlocked.has(i):
			tag = "  [SELECTED]"
		name_l.text = "%s%s" % [str(base["name"]), tag]
		stat_l.text = "Speed %d   Accel %d   Handling %d" % [int(eff["speed"]), int(eff["accel"]), int(eff["handling"])]
		desc_l.text = str(base["desc"])
		if unlocked.has(i):
			btn.text = "SELECTED" if selected == i else "SELECT"
			btn.disabled = selected == i
		else:
			btn.text = "UNLOCK - %d" % int(base["cost"])
			btn.disabled = int(_save.get("coins", 0)) < int(base["cost"])
		# Upgrade rows only for owned cars.
		for stat in ["speed", "accel", "handling"]:
			var row: HBoxContainer = _cards[i].get_node("Margin/Rows/Upgrade_%s" % stat)
			var lab: Label = row.get_node("Label")
			var ubtn: Button = row.get_node("Button")
			if not unlocked.has(i):
				row.hide()
				continue
			row.show()
			var lv := int(upg.get(stat, 0))
			var cost := CarUpgrade.upgrade_cost(lv)
			lab.text = "%s %s" % [stat.capitalize(), CarUpgrade.stars(lv)]
			if cost < 0:
				ubtn.text = "MAX"
				ubtn.disabled = true
			else:
				ubtn.text = "+ %d" % cost
				ubtn.disabled = int(_save.get("coins", 0)) < cost


func _on_action(idx: int) -> void:
	var unlocked: Array = _save.get("unlocked_cars", [0])
	if unlocked.has(idx):
		_save["selected_car"] = idx
		SaveManager.save_data(_save)
		_click()
		_refresh()
		return
	var cost := int(CarUpgrade.base_car(idx)["cost"])
	if int(_save.get("coins", 0)) >= cost:
		_save["coins"] = int(_save.get("coins", 0)) - cost
		unlocked.append(idx)
		_save["unlocked_cars"] = unlocked
		_save["selected_car"] = idx
		SaveManager.save_data(_save)
		_click()
	_refresh()


func _on_upgrade(idx: int, stat: String) -> void:
	var unlocked: Array = _save.get("unlocked_cars", [0])
	if not unlocked.has(idx):
		return
	var upg := CarUpgrade.upgrades_for(_save, idx)
	var lv := int(upg.get(stat, 0))
	var cost := CarUpgrade.upgrade_cost(lv)
	if cost < 0 or int(_save.get("coins", 0)) < cost:
		return
	_save["coins"] = int(_save.get("coins", 0)) - cost
	CarUpgrade.set_upgrade(_save, idx, stat, lv + 1)
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
