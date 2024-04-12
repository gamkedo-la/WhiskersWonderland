@tool
extends Area2D

@export var size : int = 1 : set = set_size

func set_size(value):
	size = value
	$Sprite.region_rect.size.x = 64 * size
	$CollisionShape2D.shape.size = Vector2(8 + 16 * (size-1), 8)
