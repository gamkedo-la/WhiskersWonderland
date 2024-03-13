extends Node2D

# Add your level key here
enum LEVELS { DEMO, PLAYGROUND }

# Add the level's scene here
const LEVEL_SCENES = {
	LEVELS.DEMO: preload("res://scenes/levels/demo_level.tscn"),
	LEVELS.PLAYGROUND: preload("res://scenes/levels/playground_level.tscn")
}

@export var current_level : LEVELS

func _ready():
	$DevLabel.visible = false
	load_level(current_level)

func load_level(level_key):
	Globals.current_level = level_key
	var level_scene = LEVEL_SCENES[level_key].instantiate()
	add_child(level_scene)
