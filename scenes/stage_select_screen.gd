extends Control

const MAGIC_FOREST = "res://scenes/levels/magic_forest.tscn"
const DESERT_RUINS = "res://scenes/levels/desert_ruins.tscn"
const TITLE_SCREEN = "res://title_screen.tscn"

func _on_magic_forest_pressed():
	AudioManager.intro_theme.stop()
	get_tree().change_scene_to_file(MAGIC_FOREST)

func _on_desert_ruins_pressed():
	AudioManager.intro_theme.stop()
	get_tree().change_scene_to_file(DESERT_RUINS)

func _on_back_button_pressed():
	get_tree().change_scene_to_file(TITLE_SCREEN)
