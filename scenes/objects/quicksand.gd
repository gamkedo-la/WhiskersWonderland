@tool
extends Area2D

@export var size := Vector2i(2, 2) : set = set_size

func _ready():
	# Scrolling animation
	if not Engine.is_editor_hint():
		var pos = $Sprite.global_position.x
		var tween = get_tree().create_tween().set_loops()
		tween.tween_property($Sprite, "global_position:x", pos - 16, 1.0).from(pos)
		tween.play()

func set_size(value):
	# Update collider and sprite sizes
	size = value
	size.x = clampi(size.x, 2, 40)
	size.y = clampi(size.y, 2, 24)
	$CollisionShape.position = size * 8 + Vector2i(0, 4)
	$CollisionShape.shape.size = size * 16 - Vector2i(0, 8)
	
	$Sprite.position = -Vector2.ONE
	$Sprite.size = (size * 16 + Vector2i(18, 2)) * 4
