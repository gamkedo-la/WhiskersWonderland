@tool
extends Area2D

@export var size := Vector2i(1, 1) : set = set_size

func _ready():
	# Scrolling animation
	if not Engine.is_editor_hint():
		var pos = $Sprite.global_position.x
		var tween = get_tree().create_tween().set_loops()
		tween.tween_property($Sprite, "global_position:x", pos - 16, 2.0).from(pos)
		tween.play()

func set_size(value):
	# Update collider and sprite sizes
	size = value
	$CollisionShape.position = size * 8
	$CollisionShape.shape.size = size * 16
	
	$Sprite.position = -Vector2.ONE
	$Sprite.size = ($CollisionShape.shape.size + Vector2(18, 2)) * 4
