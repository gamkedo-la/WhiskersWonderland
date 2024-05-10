extends Node2D

# Add your level key here
enum LEVELS { PITCH, PLAYGROUND, DESERT_RUINS, MAGIC_FOREST }

# Add the level's scene here
const LEVEL_SCENES = {
	LEVELS.PITCH: preload("res://scenes/levels/pitch_level.tscn"),
	LEVELS.PLAYGROUND: preload("res://scenes/levels/playground_level.tscn"),
	LEVELS.DESERT_RUINS: preload("res://scenes/levels/desert_ruins.tscn"),
	LEVELS.MAGIC_FOREST: preload("res://scenes/levels/magic_forest.tscn")
}

@export var current_level : LEVELS

func _ready():
	load_level(current_level)

func load_level(level_key):
	Globals.current_level = level_key
	var level_scene = LEVEL_SCENES[level_key].instantiate()
	add_child(level_scene)
