extends Node2D
## Street Rush game controller.
## Owns score, coins, level, difficulty, spawning, saving, audio and HUD.

const SAVE_PATH := "user://street_rush_save.cfg"
const MAX_LEVEL := 10
const SCORE_PER_LEVEL := 600.0
const LEVEL_COIN_BONUS := 25
const LEVEL_SCORE_BONUS := 100.0

# Track themes. Same list lives in themes.gd for the picker screen.
const THEMES: Array[Dictionary] = [
	{
		"name": "HIGHWAY", "desc": "Classic daylight highway.",
		"handling_mod": 1.0,
		"side": Color(0.14, 0.32, 0.18), "side_dark": Color(0.12, 0.28, 0.16),
		"road": Color(0.17, 0.18, 0.20), "edge": Color(0.88, 0.88, 0.86),
		"dash": Color(0.9, 0.9, 0.88, 0.95),
	},
	{
		"name": "DESERT", "desc": "Hot sand, red-line road.",
		"handling_mod": 1.0,
		"side": Color(0.82, 0.71, 0.51), "side_dark": Color(0.74, 0.62, 0.44),
		"road": Color(0.33, 0.32, 0.31), "edge": Color(0.88, 0.27, 0.13),
		"dash": Color(0.96, 0.92, 0.80, 0.95),
	},
	{
		"name": "ICE", "desc": "Frozen track. Slippery!",
		"handling_mod": 0.7,
		"side": Color(0.74, 0.84, 0.91), "side_dark": Color(0.64, 0.75, 0.84),
		"road": Color(0.30, 0.36, 0.44), "edge": Color(0.92, 0.96, 1.0),
		"dash": Color(0.95, 0.98, 1.0, 0.95),
	},
	{
		"name": "NIGHT", "desc": "Night drive. Amber lines.",
		"handling_mod": 1.0,
		"side": Color(0.05, 0.07, 0.10), "side_dark": Color(0.04, 0.05, 0.08),
		"road": Color(0.10, 0.11, 0.13), "edge": Color(0.95, 0.70, 0.20),
		"dash": Color(0.95, 0.85, 0.55, 0.95),
	},
]

@export var enemy_scene: PackedScene
@export var coin_scene: PackedScene

var score: float = 0.0
var coins_run: int = 0
var total_coins: int = 0
var high_score: int = 0
var best_level: int = 1
var level: int = 1
var road_speed: float = 400.0
var game_active: bool = true
var muted: bool = false

var _elapsed: float = 0.0
var _shake: float = 0.0
var _flash: float = 0.0
var _transitioning: bool = false

@onready var road = $Road
@onready var player = $Player
@onready var enemy_holder: Node2D = $EnemyHolder
@onready var coin_holder: Node2D = $CoinHolder
@onready var effects: Node2D = $Effects
@onready var enemy_timer: Timer = $EnemyTimer
@onready var coin_timer: Timer = $CoinTimer
@onready var score_label: Label = $HUD/TopBar/Margin/Rows/ScoreRow/ScoreLabel
@onready var level_label: Label = $HUD/TopBar/Margin/Rows/ScoreRow/LevelLabel
@onready var coin_label: Label = $HUD/TopBar/Margin/Rows/CoinRow/CoinLabel
@onready var health_label: Label = $HUD/TopBar/Margin/Rows/CoinRow/HealthLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_menu = $PauseMenu
@onready var hit_flash: ColorRect = $HUD/HitFlash
@onready var level_bar: ProgressBar = $HUD/TopBar/Margin/Rows/LevelBar
@onready var level_panel: PanelContainer = $HUD/LevelPanel
@onready var level_title: Label = $HUD/LevelPanel/Margin/Box/CompleteLabel
@onready var level_bonus: Label = $HUD/LevelPanel/Margin/Box/BonusLabel
@onready var continue_button: Button = $HUD/LevelPanel/Margin/Box/ContinueButton
@onready var engine_player: AudioStreamPlayer = $EnginePlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer


func _ready() -> void:
	randomize()
	_load_save()
	_apply_mute()
	_apply_selected_car()
	_apply_selected_theme()

	road.road_speed = road_speed
	enemy_timer.wait_time = 0.95
	coin_timer.wait_time = 1.4
	enemy_timer.timeout.connect(_on_enemy_tick)
	coin_timer.timeout.connect(_on_coin_tick)
	enemy_timer.start()
	coin_timer.start()

	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	player.bumped.connect(_on_player_bumped)

	pause_button.pressed.connect(_toggle_pause)
	pause_menu.resume_requested.connect(_toggle_pause)
	pause_menu.restart_requested.connect(_restart)
	pause_menu.menu_requested.connect(_to_menu)
	continue_button.pressed.connect(_on_level_continue)
	level_panel.hide()

	_start_engine()
	_update_hud()


func _process(delta: float) -> void:
	if not game_active:
		return
	if get_tree().paused:
		return

	_elapsed += delta
	road_speed = minf(400.0 + float(level - 1) * 55.0 + _elapsed * 2.0, 920.0)
	road.road_speed = road_speed
	score += road_speed * delta * 0.055

	if not _transitioning and score >= float(level) * SCORE_PER_LEVEL:
		if level >= MAX_LEVEL:
			_on_victory()
			return
		_on_level_complete()
		return

	var want_interval := maxf(0.95 - float(level - 1) * 0.08 - _elapsed * 0.0015, 0.30)
	if absf(enemy_timer.wait_time - want_interval) > 0.04:
		enemy_timer.wait_time = want_interval

	_update_engine_pitch()
	_update_hud()

	if _shake > 0.0:
		_shake = maxf(_shake - delta * 22.0, 0.0)
		position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		position = Vector2.ZERO

	if _flash > 0.0:
		_flash = maxf(_flash - delta * 2.5, 0.0)
		hit_flash.modulate.a = _flash * 0.45
	else:
		hit_flash.modulate.a = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and game_active:
		_toggle_pause()


# --- spawning ---

func _on_enemy_tick() -> void:
	if not game_active or get_tree().paused:
		return
	if enemy_scene == null:
		return
	var count := 1
	if level >= 3 and randf() < 0.30:
		count = 2
	if level >= 6 and randf() < 0.12:
		count = 3
	# Never block every lane at once.
	count = mini(count, 3)

	var order: Array = road.lanes.duplicate()
	order.shuffle()
	var player_lane: int = road.lane_index_for_x(player.position.x)

	var picked: Array[float] = []
	for lx in order:
		if picked.size() >= count:
			break
		var li: int = road.lane_index_for_x(float(lx))
		# Do not drop a car right on top of the player low on screen.
		if li == player_lane and randf() < 0.75 and picked.is_empty() and count < 4:
			continue
		picked.append(float(lx))
	if picked.is_empty():
		picked.append(float(order[(player_lane + 2) % order.size()]))

	for lx in picked:
		var e = enemy_scene.instantiate()
		enemy_holder.add_child(e)
		var spd := road_speed * randf_range(0.45, 0.68) + float(level - 1) * 8.0
		spd = clampf(spd, 190.0, 640.0)
		e.setup(spd, lx, randf_range(-110.0, -50.0))


func _on_coin_tick() -> void:
	if not game_active or get_tree().paused:
		return
	if coin_scene == null:
		return
	var c = coin_scene.instantiate()
	coin_holder.add_child(c)
	c.position = Vector2(road.random_lane_x() + randf_range(-8.0, 8.0), -40.0)
	c.fall_speed = road_speed
	c.collected.connect(_on_coin_collected)
	# Small line of coins feels rewarding.
	if randf() < 0.45:
		var c2 = coin_scene.instantiate()
		coin_holder.add_child(c2)
		c2.position = c.position + Vector2(0, -52)
		c2.fall_speed = road_speed
		c2.collected.connect(_on_coin_collected)


func _on_coin_collected(coin: Area2D) -> void:
	if not game_active:
		return
	coins_run += 1
	total_coins += 1
	score += 50.0
	_spawn_sparkle(coin.position)
	_play_coin()
	_update_hud()


# --- damage / levels ---

func _on_health_changed(_hp: int) -> void:
	_update_hud()


func _on_player_bumped() -> void:
	_shake = 7.0
	_flash = 1.0
	_spawn_crash(player.position)
	_play_crash()
	_update_hud()


func _on_player_died() -> void:
	if not game_active:
		return
	game_active = false
	_shake = 12.0
	_flash = 1.0
	_spawn_crash(player.position)
	_play_crash()
	enemy_timer.stop()
	coin_timer.stop()
	_stop_engine()
	_save_run()
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func _on_level_complete() -> void:
	_transitioning = true
	coins_run += LEVEL_COIN_BONUS
	total_coins += LEVEL_COIN_BONUS
	score += LEVEL_SCORE_BONUS
	best_level = maxi(best_level, level)
	_save_progress()
	_play_level()
	get_tree().paused = true
	engine_player.stream_paused = true
	level_title.text = "LEVEL %d COMPLETE!" % level
	level_bonus.text = "Bonus: +%d coins   +%d pts" % [LEVEL_COIN_BONUS, int(LEVEL_SCORE_BONUS)]
	level_panel.show()
	continue_button.grab_focus()
	_update_hud()
	await get_tree().create_timer(3.0, true, false, true).timeout
	_on_level_continue()


func _on_level_continue() -> void:
	if not _transitioning or not game_active:
		return
	_transitioning = false
	level = mini(level + 1, MAX_LEVEL)
	level_panel.hide()
	get_tree().paused = false
	engine_player.stream_paused = false
	_update_hud()


func _on_victory() -> void:
	if not game_active:
		return
	game_active = false
	_transitioning = false
	enemy_timer.stop()
	coin_timer.stop()
	_stop_engine()
	best_level = MAX_LEVEL
	_save_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Victory.tscn")


# --- pause / nav ---

func _toggle_pause() -> void:
	if not game_active or _transitioning:
		return
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		pause_menu.show_pause()
		engine_player.stream_paused = true
	else:
		pause_menu.hide_pause()
		engine_player.stream_paused = false
	_play_click()


func _restart() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _update_hud() -> void:
	score_label.text = "SCORE: %d" % int(score)
	level_label.text = "LEVEL %d/%d" % [mini(level, MAX_LEVEL), MAX_LEVEL]
	coin_label.text = "COINS: %d" % coins_run
	level_bar.max_value = SCORE_PER_LEVEL
	level_bar.value = clampf(score - float(maxi(level, 1) - 1) * SCORE_PER_LEVEL, 0.0, SCORE_PER_LEVEL)
	var hearts := ""
	for i in range(player.max_health):
		hearts += "♥ " if i < player.health else "♡ "
	health_label.text = "HEALTH: " + hearts.strip_edges()


# --- effects ---

func _spawn_sparkle(at: Vector2) -> void:
	for i in range(8):
		var p := ColorRect.new()
		p.color = Color(1.0, 0.81, 0.2, 1.0)
		p.size = Vector2(4, 4)
		p.position = at + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		effects.add_child(p)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-26, 26), randf_range(-30, 10)), 0.4)
		tw.tween_property(p, "modulate:a", 0.0, 0.4)
		tw.chain().tween_callback(p.queue_free)


func _spawn_crash(at: Vector2) -> void:
	for i in range(14):
		var p := ColorRect.new()
		p.color = Color(1.0, 0.45, 0.2, 1.0) if i % 2 == 0 else Color(0.25, 0.25, 0.28, 1.0)
		p.size = Vector2(5, 5)
		p.position = at + Vector2(randf_range(-10, 10), randf_range(-14, 14))
		effects.add_child(p)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-60, 60), randf_range(-70, 30)), 0.5)
		tw.tween_property(p, "rotation", randf_range(-2.0, 2.0), 0.5)
		tw.tween_property(p, "modulate:a", 0.0, 0.5)
		tw.chain().tween_callback(p.queue_free)


# --- save ---

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = int(cfg.get_value("save", "high_score", 0))
	total_coins = int(cfg.get_value("save", "total_coins", 0))
	best_level = maxi(1, int(cfg.get_value("save", "best_level", 1)))
	muted = bool(cfg.get_value("save", "muted", false))


func _save_run() -> void:
	var final := int(score)
	if final > high_score:
		high_score = final
	if level > best_level:
		best_level = level
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("save", "high_score", high_score)
	cfg.set_value("save", "total_coins", total_coins)
	cfg.set_value("save", "best_level", best_level)
	cfg.set_value("save", "last_score", final)
	cfg.set_value("save", "last_coins", coins_run)
	cfg.set_value("save", "last_level", level)
	cfg.save(SAVE_PATH)


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("save", "total_coins", total_coins)
	cfg.set_value("save", "best_level", best_level)
	if int(score) > high_score:
		high_score = int(score)
		cfg.set_value("save", "high_score", high_score)
	cfg.save(SAVE_PATH)


func _apply_selected_car() -> void:
	var cfg := ConfigFile.new()
	var selected := 0
	if cfg.load(SAVE_PATH) == OK:
		selected = int(cfg.get_value("save", "selected", 0))
	player.apply_car_stats(_car_for_index(selected))


func _apply_selected_theme() -> void:
	var cfg := ConfigFile.new()
	var theme_idx := 0
	if cfg.load(SAVE_PATH) == OK:
		theme_idx = clampi(int(cfg.get_value("save", "theme", 0)), 0, THEMES.size() - 1)
	var theme: Dictionary = THEMES[theme_idx]
	road.apply_theme(theme)
	player.handling *= float(theme.get("handling_mod", 1.0))


func _car_for_index(i: int) -> Dictionary:
	match i:
		1:
			return {"speed": 80.0, "handling": 70.0, "color": Color(0.85, 0.2, 0.22)}
		2:
			return {"speed": 95.0, "handling": 60.0, "color": Color(0.95, 0.75, 0.2)}
	return {"speed": 60.0, "handling": 80.0, "color": Color(0.18, 0.55, 1.0)}


# --- audio ---
# Each helper first looks for an optional wav file in assets/sounds.
# If nothing is there it plays a small generated tone, so the game
# never errors when audio files are missing.

func _audio_file(path: String) -> AudioStream:
	if FileAccess.file_exists(path):
		var s := load(path)
		if s is AudioStream:
			return s
	return null


func _tone(freq: float, dur: float, volume: float = 0.5, slide_to: float = 0.0) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * dur)
	var data := PackedByteArray()
	data.resize(frames)
	var end_f := slide_to if slide_to > 0.0 else freq
	for i in range(frames):
		var t := float(i) / float(rate)
		var k := float(i) / float(maxi(frames - 1, 1))
		var f := lerpf(freq, end_f, k)
		data[i] = int(128.0 + 90.0 * volume * sin(TAU * f * t))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


func _play_one_shot(stream: AudioStream) -> void:
	if muted or stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()


func _play_click() -> void:
	var f := _audio_file("res://assets/sounds/click.wav")
	_play_one_shot(f if f else _tone(660.0, 0.07, 0.4))


func _play_coin() -> void:
	var f := _audio_file("res://assets/sounds/coin.wav")
	_play_one_shot(f if f else _tone(990.0, 0.12, 0.45, 1560.0))


func _play_crash() -> void:
	var f := _audio_file("res://assets/sounds/crash.wav")
	_play_one_shot(f if f else _tone(160.0, 0.35, 0.6, 60.0))


func _play_level() -> void:
	var f := _audio_file("res://assets/sounds/level.wav")
	_play_one_shot(f if f else _tone(520.0, 0.18, 0.4, 880.0))


func _start_engine() -> void:
	if muted:
		return
	var f := _audio_file("res://assets/sounds/engine.wav")
	if f:
		if f is AudioStreamWAV:
			f.loop_mode = AudioStreamWAV.LOOP_FORWARD
			f.loop_begin = 0
			var bytes_per_frame := 2 if f.stereo else 1
			if f.format == AudioStreamWAV.FORMAT_16_BITS:
				bytes_per_frame *= 2
			f.loop_end = int(f.data.size() / bytes_per_frame)
		engine_player.stream = f
		engine_player.volume_db = -14.0
		engine_player.play()
		return
	var rate := 22050
	var frames := int(rate * 0.5)
	var data := PackedByteArray()
	data.resize(frames)
	for i in range(frames):
		var t := float(i) / float(rate)
		data[i] = int(128.0 + 40.0 * sin(TAU * 82.0 * t) + 18.0 * sin(TAU * 164.0 * t))
	var loop := AudioStreamWAV.new()
	loop.format = AudioStreamWAV.FORMAT_8_BITS
	loop.mix_rate = rate
	loop.stereo = false
	loop.data = data
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = frames
	engine_player.stream = loop
	engine_player.volume_db = -14.0
	engine_player.play()


func _update_engine_pitch() -> void:
	if engine_player.playing:
		engine_player.pitch_scale = 0.85 + road_speed / 1400.0


func _stop_engine() -> void:
	engine_player.stop()


func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)
