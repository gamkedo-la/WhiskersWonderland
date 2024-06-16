extends Node2D

const STAGE_SELECT = preload("res://scenes/stage_select_screen.tscn")

@export var SCROLL_SPEED : float = 100.0

@onready var scroll = $Scroll

func _ready():
	get_viewport().canvas_transform.origin = Vector2.ZERO

func _process(delta):
	var speed_factor = 6.0 if Input.is_anything_pressed() else 1.0
	scroll.position.y -= speed_factor * SCROLL_SPEED * delta

func _on_back_pressed():
	get_tree().change_scene_to_packed(STAGE_SELECT)
