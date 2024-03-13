extends Node

var camera : Node2D
var current_level : int

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # This script still executes during game pause

func is_paused():
	return get_tree().paused

func pause():
	get_tree().paused = true

func resume():
	get_tree().paused = false
