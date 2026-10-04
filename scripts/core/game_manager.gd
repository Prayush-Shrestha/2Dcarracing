class_name GameManager
extends RefCounted
## Shared run context + scene navigation.
## Holds which level the player picked in Level Select so Game.tscn
## can start the correct distance/theme without fragile globals.
## All scene paths live here so folder refactors only touch one file.

const SCENE_MAIN_MENU := "res://scenes/main/MainMenu.tscn"
const SCENE_GAME := "res://scenes/gameplay/Game.tscn"
const SCENE_LEVEL_SELECT := "res://scenes/gameplay/LevelSelect.tscn"
const SCENE_GARAGE := "res://scenes/garage/Garage.tscn"
const SCENE_TRACKS := "res://scenes/menus/Themes.tscn"
const SCENE_SETTINGS := "res://scenes/menus/Settings.tscn"
const SCENE_PAUSE := "res://scenes/menus/PauseMenu.tscn"
const SCENE_GAME_OVER := "res://scenes/menus/GameOver.tscn"
const SCENE_VICTORY := "res://scenes/menus/Victory.tscn"

# Level chosen from Level Select / Main Menu. Static so it survives scene changes.
static var pending_level: int = 1
# Optional environment override from the TRACKS screen (free race).
# Empty = use the level's own theme_id. Set via start_theme_run().
static var pending_theme_id: String = ""
static var last_distance: float = 0.0
static var last_score: int = 0
static var last_coins: int = 0


static func start_level(tree: SceneTree, level_number: int) -> void:
	pending_level = clampi(level_number, 1, LevelManager.MAX_LEVEL)
	pending_theme_id = ""
	tree.paused = false
	tree.change_scene_to_file(SCENE_GAME)


## Free race from the theme picker: race <level_number> distance rules
## but render + handle the chosen environment instead of the level theme.
static func start_theme_run(tree: SceneTree, theme_id: String, level_number: int = -1) -> void:
	if level_number < 0:
		var data := SaveManager.load_data()
		level_number = clampi(int(data.get("current_level", 1)), 1, LevelManager.MAX_LEVEL)
	pending_level = clampi(level_number, 1, LevelManager.MAX_LEVEL)
	pending_theme_id = String(theme_id)
	tree.paused = false
	tree.change_scene_to_file(SCENE_GAME)


## Which environment should Game use? Override wins, else level default.
static func resolve_theme_id(level_def: Dictionary) -> String:
	if pending_theme_id != "":
		return pending_theme_id
	return str(level_def.get("theme_id", "rock_mountain"))


static func quick_play(tree: SceneTree) -> void:
	var data := SaveManager.load_data()
	var current := clampi(int(data.get("current_level", 1)), 1, LevelManager.MAX_LEVEL)
	# Quick PLAY continues at the highest unlocked, uncompleted level.
	var unlocked: Array = data.get("unlocked_levels", [1])
	var completed: Array = data.get("completed_levels", [])
	var target := current
	for lv: int in range(1, LevelManager.MAX_LEVEL + 1):
		if unlocked.has(lv) and not completed.has(lv):
			target = lv
			break
	start_level(tree, target)


static func restart(tree: SceneTree) -> void:
	tree.paused = false
	tree.change_scene_to_file(SCENE_GAME)


static func to_menu(tree: SceneTree) -> void:
	tree.paused = false
	tree.change_scene_to_file(SCENE_MAIN_MENU)


static func to_levels(tree: SceneTree) -> void:
	tree.paused = false
	tree.change_scene_to_file(SCENE_LEVEL_SELECT)


static func to_garage(tree: SceneTree) -> void:
	tree.change_scene_to_file(SCENE_GARAGE)


static func clamp_pending() -> void:
	pending_level = clampi(pending_level, 1, LevelManager.MAX_LEVEL)
