extends Node

var debug_mode : bool = false

var camera : Node2D
var current_level : int

var player_pos : Vector2

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # This script still executes during game pause

func is_paused():
	return get_tree().paused

func pause():
	get_tree().paused = true

func resume():
	get_tree().paused = false
