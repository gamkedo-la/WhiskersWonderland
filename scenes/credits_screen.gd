extends Node2D

@export var SCROLL_SPEED : float = 100.0

@onready var scroll = $Scroll

func _process(delta):
	scroll.position.y -= SCROLL_SPEED * delta

func _on_timer_timeout():
	SCROLL_SPEED = 0.0
