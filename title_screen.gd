extends Node2D

const GAME_SCENE = preload("res://scenes/game.tscn")

func _process(delta):
	if Input.is_action_just_pressed("start"):
		get_tree().change_scene_to_packed(GAME_SCENE)
