extends CanvasLayer
## Pause overlay. Shown and hidden by Game.gd. Works while tree is paused.

signal resume_requested
signal restart_requested
signal menu_requested

@onready var dim: ColorRect = $Dim
@onready var resume_button: Button = $Center/Box/ResumeButton
@onready var restart_button: Button = $Center/Box/RestartButton
@onready var menu_button: Button = $Center/Box/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide_pause()
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	menu_button.pressed.connect(func() -> void: menu_requested.emit())


func show_pause() -> void:
	show()
	resume_button.grab_focus()


func hide_pause() -> void:
	hide()
