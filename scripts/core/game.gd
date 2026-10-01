extends Node2D
## Street Rush run controller (one level attempt).
## Distance-based progression via LevelManager, persistence via
## SaveManager, audio via AudioManager, spawning via EnemySpawner.
## Level theme comes from the level definition.

const METERS_PER_PIXEL := 0.05
const SCORE_RATE := 0.055
const MAX_ROAD_SPEED := 920.0

@export var enemy_scene: PackedScene
@export var coin_scene: PackedScene
@export var powerup_scene: PackedScene

var score: float = 0.0
var coins_run: int = 0
var distance_m: float = 0.0
var target_distance: float = 1000.0
var level: int = 1
var level_def: Dictionary = {}
var road_speed: float = 400.0
var game_active: bool = true

var _save: Dictionary = {}
var _elapsed: float = 0.0
var _shake: float = 0.0
var _flash: float = 0.0
var _transitioning: bool = false
var _powerup_tick: float = 8.0
var _nitro_was_active: bool = false

const HELP_AUTO_HIDE := 8.0
var _help_visible: bool = true
var _help_elapsed: float = 0.0

@onready var road = $Road
@onready var player = $Player
@onready var enemy_holder: Node2D = $EnemyHolder
@onready var coin_holder: Node2D = $CoinHolder
@onready var effects: Node2D = $Effects
@onready var enemy_timer: Timer = $EnemyTimer
@onready var coin_timer: Timer = $CoinTimer
@onready var powerup_timer: Timer = $PowerupTimer
@onready var score_label: Label = $HUD/TopBar/Margin/Rows/ScoreRow/ScoreLabel
@onready var level_label: Label = $HUD/TopBar/Margin/Rows/ScoreRow/LevelLabel
@onready var coin_label: Label = $HUD/TopBar/Margin/Rows/CoinRow/CoinLabel
@onready var health_label: Label = $HUD/TopBar/Margin/Rows/CoinRow/HealthLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_menu = $PauseMenu
@onready var hit_flash: ColorRect = $HUD/HitFlash
@onready var level_bar: ProgressBar = $HUD/TopBar/Margin/Rows/LevelBar
@onready var level_panel: PanelContainer = $HUD/LevelPanel
@onready var help_panel: PanelContainer = $HUD/HelpPanel
@onready var help_button: Button = $HUD/HelpButton
@onready var help_close_button: Button = $HUD/HelpPanel/Margin/Box/CloseButton
@onready var level_title: Label = $HUD/LevelPanel/Margin/Box/CompleteLabel
@onready var level_bonus: Label = $HUD/LevelPanel/Margin/Box/BonusLabel
@onready var continue_button: Button = $HUD/LevelPanel/Margin/Box/ContinueButton
@onready var engine_player: AudioStreamPlayer = $EnginePlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var nitro_player: AudioStreamPlayer = $NitroPlayer

var _distance_label: Label = null
var _nitro_bar: ProgressBar = null
var _status_label: Label = null


func _ready() -> void:
	randomize()
	GameManager.clamp_pending()
	_save = SaveManager.load_data()
	level = clampi(GameManager.pending_level, 1, LevelManager.MAX_LEVEL)
	level_def = LevelManager.get_level(level)
	target_distance = float(level_def.get("distance", 1000.0))
	AudioManager.apply_volumes(float(_save.get("music_volume", 0.8)), float(_save.get("sfx_volume", 0.9)), bool(_save.get("muted", false)))
	_apply_selected_car()
	_apply_level_theme()

	_ensure_hud_nodes()
	road.road_speed = road_speed
	enemy_timer.wait_time = float(level_def.get("spawn_interval", 0.9))
	coin_timer.wait_time = 1.4
	if powerup_timer != null:
		powerup_timer.wait_time = PowerUpDef.SPAWN_INTERVAL
		enemy_timer.timeout.connect(_on_enemy_tick)
		coin_timer.timeout.connect(_on_coin_tick)
		powerup_timer.timeout.connect(_on_powerup_tick)
	else:
		enemy_timer.timeout.connect(_on_enemy_tick)
		coin_timer.timeout.connect(_on_coin_tick)
	enemy_timer.start()
	coin_timer.start()
	if powerup_timer != null:
		powerup_timer.start()

	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	player.bumped.connect(_on_player_bumped)
	if player.has_signal("nitro_changed"):
		player.nitro_changed.connect(_on_nitro_changed)
	if player.has_signal("shield_changed"):
		player.shield_changed.connect(_on_power_state_changed.bind("shield"))
	if player.has_signal("magnet_changed"):
		player.magnet_changed.connect(_on_power_state_changed.bind("magnet"))

	pause_button.pressed.connect(_toggle_pause)
	pause_menu.resume_requested.connect(_toggle_pause)
	pause_menu.restart_requested.connect(_restart)
	pause_menu.menu_requested.connect(_to_menu)
	if pause_menu.has_signal("levels_requested"):
		pause_menu.levels_requested.connect(_to_levels)
	continue_button.pressed.connect(_on_level_continue)
	_ensure_level_panel_buttons()
	level_panel.hide()

	help_button.pressed.connect(_toggle_help)
	help_close_button.pressed.connect(_on_help_close)
	help_panel.show()
	_help_visible = true
	_help_elapsed = 0.0

	_start_engine()
	_update_hud()


func _process(delta: float) -> void:
	if not game_active:
		return
	if get_tree().paused:
		return
	_elapsed += delta
	var base := 400.0 + float(level - 1) * 35.0 + _elapsed * 2.0
	var nitro_mult := 1.45 if player.get("nitro_active") else 1.0
	road_speed = minf(base * nitro_mult, MAX_ROAD_SPEED)
	road.road_speed = road_speed
	score += road_speed * delta * SCORE_RATE
	distance_m += road_speed * delta * METERS_PER_PIXEL
	_update_magnet_pull(delta)

	if not _transitioning and distance_m >= target_distance:
		if level >= LevelManager.MAX_LEVEL:
			_on_victory()
			return
		_on_level_complete()
		return

	var want_interval := maxf(float(level_def.get("spawn_interval", 0.9)) - _elapsed * 0.0015, 0.30)
	if absf(enemy_timer.wait_time - want_interval) > 0.04:
		enemy_timer.wait_time = want_interval

	if _help_visible:
		_help_elapsed += delta
		if _help_elapsed >= HELP_AUTO_HIDE:
			_hide_help()

	_update_engine_pitch()
	_update_hud()
	_update_nitro_audio()

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
	if not game_active:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_toggle_pause()


# --- spawning ---

func _on_enemy_tick() -> void:
	if not game_active or get_tree().paused:
		return
	if enemy_scene == null:
		return
	var count := EnemySpawner.pick_count(level)
	var player_lane: int = road.lane_index_for_x(player.position.x)
	var picked: Array = EnemySpawner.pick_lanes(road.lanes, player_lane, count)
	for lx in picked:
		var e = enemy_scene.instantiate()
		enemy_holder.add_child(e)
		var etype := EnemySpawner.pick_type(level)
		var mult := float(level_def.get("enemy_speed_mult", 1.0))
		var spd := (road_speed * randf_range(0.45, 0.68) + float(level - 1) * 8.0) * mult
		spd = clampf(spd, 190.0, 660.0)
		if e.has_method("setup"):
			e.setup(spd, float(lx), randf_range(-110.0, -50.0), etype)
		else:
			e.setup(spd, float(lx), randf_range(-110.0, -50.0))


func _on_coin_tick() -> void:
	if not game_active or get_tree().paused:
		return
	if coin_scene == null:
		return
	_spawn_coin(road.random_lane_x() + randf_range(-8.0, 8.0), -40.0)
	if randf() < 0.45:
		_spawn_coin(road.random_lane_x() + randf_range(-8.0, 8.0), -92.0)


func _spawn_coin(x: float, y: float) -> void:
	var c = coin_scene.instantiate()
	coin_holder.add_child(c)
	c.position = Vector2(x, y)
	c.fall_speed = road_speed
	if c.has_signal("collected"):
		c.collected.connect(_on_coin_collected)


func _on_coin_collected(coin: Area2D) -> void:
	if not game_active:
		return
	var mult := float(level_def.get("coin_multiplier", 1.0))
	coins_run += 1
	_save["coins"] = int(_save.get("coins", 0)) + 1
	_save["total_coins_earned"] = int(_save.get("total_coins_earned", 0)) + 1
	score += 50.0 * mult
	_spawn_sparkle(coin.position)
	_play_kind("coin")
	_update_hud()


func _on_powerup_tick() -> void:
	if not game_active or get_tree().paused:
		return
	if powerup_scene == null:
		return
	var p = powerup_scene.instantiate()
	coin_holder.add_child(p)
	var kind := PowerUpDef.KIND_SHIELD if randf() < 0.5 else PowerUpDef.KIND_MAGNET
	p.position = Vector2(road.random_lane_x(), -50.0)
	if p.has_method("setup"):
		p.setup(kind, road_speed)
	if p.has_signal("picked"):
		p.picked.connect(_on_powerup_picked)


func _on_powerup_picked(kind: String, at: Vector2) -> void:
	if not game_active:
		return
	if kind == PowerUpDef.KIND_SHIELD:
		player.set_shield(true)
	else:
		player.set_magnet(PowerUpDef.MAGNET_DURATION)
	_spawn_sparkle(at)
	_play_kind("powerup")
	_update_hud()


func _update_magnet_pull(delta: float) -> void:
	if not bool(player.get("magnet_active")):
		return
	for c in coin_holder.get_children():
		if not c.is_in_group("coin"):
			continue
		var to_player: Vector2 = player.global_position - c.global_position
		if to_player.length() < PowerUpDef.MAGNET_RADIUS:
			c.position += to_player.normalized() * 420.0 * delta


# --- damage / levels ---

func _on_health_changed(_hp: int) -> void:
	_update_hud()


func _on_player_bumped() -> void:
	_shake = 7.0
	_flash = 1.0
	_spawn_crash(player.position)
	_play_kind("crash")
	_update_hud()


func _on_nitro_changed(_v: float, _m: float, _a: bool) -> void:
	_update_hud()


func _on_power_state_changed(_active: bool, _kind: String) -> void:
	_update_hud()


func _on_player_died() -> void:
	if not game_active:
		return
	game_active = false
	_shake = 12.0
	_flash = 1.0
	_spawn_crash(player.position)
	_play_kind("crash")
	enemy_timer.stop()
	coin_timer.stop()
	if powerup_timer != null:
		powerup_timer.stop()
	_stop_engine()
	_save_run()
	GameManager.last_distance = distance_m
	GameManager.last_score = int(score)
	GameManager.last_coins = coins_run
	await get_tree().create_timer(1.0).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(GameManager.SCENE_GAME_OVER)


func _on_level_complete() -> void:
	_transitioning = true
	var reward := int(level_def.get("reward", 100))
	coins_run += reward
	_save["coins"] = int(_save.get("coins", 0)) + reward
	_save["total_coins_earned"] = int(_save.get("total_coins_earned", 0)) + reward
	score += 100.0
	LevelManager.complete_level(level, _save)
	_save["last_score"] = int(score)
	_save["last_coins"] = coins_run
	_save["last_level"] = level
	_save["last_distance"] = distance_m
	if int(score) > int(_save.get("high_score", 0)):
		_save["high_score"] = int(score)
	SaveManager.save_data(_save)
	_play_kind("level")
	get_tree().paused = true
	if engine_player != null:
		engine_player.stream_paused = true
	var lname: String = str(level_def.get("name", "LEVEL %d" % level))
	level_title.text = "%s COMPLETE!" % lname
	level_bonus.text = "Reward: +%d coins   Distance: %dm" % [reward, int(target_distance)]
	level_panel.show()
	continue_button.grab_focus()
	_update_hud()
	await get_tree().create_timer(3.0, true, false, true).timeout
	_on_level_continue()


func _on_level_continue() -> void:
	if not _transitioning or not game_active:
		return
	_transitioning = false
	level_panel.hide()
	get_tree().paused = false
	if engine_player != null:
		engine_player.stream_paused = false
	if level >= LevelManager.MAX_LEVEL:
		_on_victory()
		return
	GameManager.pending_level = mini(level + 1, LevelManager.MAX_LEVEL)
	get_tree().reload_current_scene()


func _on_victory() -> void:
	if not game_active:
		return
	game_active = false
	_transitioning = false
	enemy_timer.stop()
	coin_timer.stop()
	if powerup_timer != null:
		powerup_timer.stop()
	_stop_engine()
	var reward := int(level_def.get("reward", 1000))
	_save["coins"] = int(_save.get("coins", 0)) + reward
	if int(score) > int(_save.get("high_score", 0)):
		_save["high_score"] = int(score)
	if not (_save.get("completed_levels", []) as Array).has(LevelManager.MAX_LEVEL):
		(_save.get("completed_levels", []) as Array).append(LevelManager.MAX_LEVEL)
	_save["last_score"] = int(score)
	_save["last_coins"] = coins_run
	_save["last_level"] = level
	_save["last_distance"] = distance_m
	SaveManager.save_data(_save)
	GameManager.last_distance = distance_m
	GameManager.last_score = int(score)
	GameManager.last_coins = coins_run
	get_tree().paused = false
	get_tree().change_scene_to_file(GameManager.SCENE_VICTORY)


# --- pause / nav ---

func _toggle_pause() -> void:
	if not game_active or _transitioning:
		return
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		pause_menu.show_pause()
		if engine_player != null:
			engine_player.stream_paused = true
	else:
		pause_menu.hide_pause()
		if engine_player != null:
			engine_player.stream_paused = false
	_play_kind("click")


func _toggle_help() -> void:
	if _help_visible:
		_hide_help()
		_play_kind("click")
	else:
		_help_visible = true
		_help_elapsed = HELP_AUTO_HIDE
		help_panel.show()
		_play_kind("click")


func _on_help_close() -> void:
	_hide_help()
	_play_kind("click")


func _hide_help() -> void:
	_help_visible = false
	_help_elapsed = HELP_AUTO_HIDE
	help_panel.hide()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _to_menu() -> void:
	GameManager.to_menu(get_tree())


func _to_levels() -> void:
	GameManager.to_levels(get_tree())


func _update_hud() -> void:
	score_label.text = "SCORE: %d" % int(score)
	var lname: String = str(level_def.get("name", "LEVEL %d" % level))
	level_label.text = "LV %d/10" % level
	coin_label.text = "COINS: %d" % coins_run
	level_bar.max_value = target_distance
	level_bar.value = clampf(distance_m, 0.0, target_distance)
	var hearts := ""
	for i in range(player.max_health):
		hearts += "♥ " if i < player.health else "♡ "
	health_label.text = "HEALTH: " + hearts.strip_edges()
	if _distance_label != null:
		_distance_label.text = "%s  •  %dm / %dm" % [lname, int(distance_m), int(target_distance)]
	if _nitro_bar != null:
		_nitro_bar.max_value = 100.0
		_nitro_bar.value = float(player.get("_nitro")) if player.get("_nitro") != null else 100.0
	if _status_label != null:
		var parts: Array[String] = []
		if bool(player.get("shield_active")):
			parts.append("SHIELD")
		if bool(player.get("magnet_active")):
			parts.append("MAGNET")
		if bool(player.get("nitro_active")):
			parts.append("NITRO!")
		_status_label.text = "  ".join(parts)
		_status_label.visible = not parts.is_empty()


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
	if bool(player.get("nitro_active")):
		pass


func _spawn_nitro_flame() -> void:
	var p := ColorRect.new()
	p.color = Color(0.4, 0.7, 1.0, 0.9)
	p.size = Vector2(6, 10)
	p.position = player.position + Vector2(randf_range(-8, 8), 38)
	effects.add_child(p)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(p, "position", p.position + Vector2(0, 46), 0.25)
	tw.tween_property(p, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(p.queue_free)


# --- save ---

func _save_run() -> void:
	if int(score) > int(_save.get("high_score", 0)):
		_save["high_score"] = int(score)
	_save["last_score"] = int(score)
	_save["last_coins"] = coins_run
	_save["last_level"] = level
	_save["last_distance"] = distance_m
	_save["current_level"] = level
	SaveManager.save_data(_save)


func _apply_selected_car() -> void:
	var idx := int(_save.get("selected_car", 0))
	var upgrades: Dictionary = CarUpgrade.upgrades_for(_save, idx)
	player.apply_car_stats(CarUpgrade.effective_stats(idx, upgrades))


func _apply_level_theme() -> void:
	var theme_idx := int(level_def.get("theme_index", 0))
	# MIXED / CHAMPIONSHIP fall back to highway visuals with full difficulty.
	road.apply_theme_index(theme_idx)
	var theme := road.theme_for_index(theme_idx)
	player.handling *= float(theme.get("handling_mod", 1.0))


# --- audio ---

func _play_kind(kind: String) -> void:
	if bool(_save.get("muted", false)):
		return
	AudioManager.play(sfx_player, kind, false)


func _start_engine() -> void:
	if bool(_save.get("muted", false)):
		return
	engine_player.stream = AudioManager.make_engine_loop()
	engine_player.volume_db = -14.0
	engine_player.play()


func _update_engine_pitch() -> void:
	if engine_player.playing:
		var boost := 1.15 if bool(player.get("nitro_active")) else 1.0
		engine_player.pitch_scale = (0.85 + road_speed / 1400.0) * boost


func _update_nitro_audio() -> void:
	var is_active := bool(player.get("nitro_active"))
	if is_active and not _nitro_was_active:
		AudioManager.play(nitro_player, "nitro", bool(_save.get("muted", false)))
		nitro_player.pitch_scale = 1.0
	if is_active and Engine.get_process_frames() % 6 == 0:
		_spawn_nitro_flame()
	_nitro_was_active = is_active


func _stop_engine() -> void:
	engine_player.stop()
	if nitro_player != null:
		nitro_player.stop()


# --- HUD helpers (code-built so old scenes keep working) ---

func _ensure_hud_nodes() -> void:
	var rows: VBoxContainer = $HUD/TopBar/Margin/Rows
	if not has_node("HUD/TopBar/Margin/Rows/DistanceLabel"):
		_distance_label = Label.new()
		_distance_label.name = "DistanceLabel"
		_distance_label.add_theme_font_size_override("font_size", 15)
		_distance_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		rows.add_child(_distance_label)
		rows.move_child(_distance_label, 2)
	else:
		_distance_label = $HUD/TopBar/Margin/Rows/DistanceLabel
	if not has_node("HUD/TopBar/Margin/Rows/NitroRow"):
		var nitro_row := HBoxContainer.new()
		nitro_row.name = "NitroRow"
		nitro_row.add_theme_constant_override("separation", 8)
		var lab := Label.new()
		lab.text = "NITRO"
		lab.add_theme_font_size_override("font_size", 14)
		lab.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		nitro_row.add_child(lab)
		_nitro_bar = ProgressBar.new()
		_nitro_bar.name = "NitroBar"
		_nitro_bar.custom_minimum_size = Vector2(0, 10)
		_nitro_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_nitro_bar.max_value = 100.0
		_nitro_bar.value = 100.0
		_nitro_bar.show_percentage = false
		nitro_row.add_child(_nitro_bar)
		rows.add_child(nitro_row)
	else:
		_nitro_bar = $HUD/TopBar/Margin/Rows/NitroRow/NitroBar
	if not has_node("HUD/StatusLabel"):
		_status_label = Label.new()
		_status_label.name = "StatusLabel"
		_status_label.add_theme_font_size_override("font_size", 18)
		_status_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.anchor_left = 0.5
		_status_label.anchor_right = 0.5
		_status_label.offset_left = -100.0
		_status_label.offset_right = 100.0
		_status_label.offset_top = 150.0
		_status_label.offset_bottom = 175.0
		$HUD.add_child(_status_label)
	else:
		_status_label = $HUD/StatusLabel


func _ensure_level_panel_buttons() -> void:
	var box: VBoxContainer = $HUD/LevelPanel/Margin/Box
	if not has_node("HUD/LevelPanel/Margin/Box/LevelsButton"):
		var b := Button.new()
		b.name = "LevelsButton"
		b.text = "LEVELS"
		b.custom_minimum_size = Vector2(220, 44)
		b.add_theme_font_size_override("font_size", 18)
		box.add_child(b)
		b.pressed.connect(_to_levels)
