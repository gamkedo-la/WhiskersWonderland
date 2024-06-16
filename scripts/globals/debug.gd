extends Node

signal kill_player
signal reloaded_scene

const BUILD_VERSION = "0.1.5"

func _ready():
	if Globals.debug_mode:
		print("Build v%s" % [BUILD_VERSION])
	process_mode = Node.PROCESS_MODE_ALWAYS # This script still executes during game pause

### Controls for Debugging
func _process(_delta):
	# Debug controls
	if Globals.debug_mode:
		if Input.is_action_just_pressed("debug_exit"):
			quit()

		if Input.is_action_just_pressed("debug_reload"):
			reload_scene()

		if Input.is_action_just_pressed("debug_user_folder"):
			Globals.pause()
			OS.shell_open(ProjectSettings.globalize_path("user://"))

		if Input.is_action_just_pressed("debug_slow"):
			Engine.time_scale = clamp(Engine.time_scale - 0.25, 0.25, 4.0)
			print('Slowed down (%s)' % [Engine.time_scale])

		if Input.is_action_just_pressed("debug_fast"):
			Engine.time_scale = clamp(Engine.time_scale + 0.25, 0.25, 4.0)
			print('Speed up (%s)' % [Engine.time_scale])

		if Input.is_action_just_pressed("debug_die"):
			print('Killed player')
			kill_player.emit()

func quit():
	print('Quit')
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func reload_scene():
	print('Reloaded scene')
	get_tree().reload_current_scene()
	reloaded_scene.emit()
