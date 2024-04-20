@tool
extends Area2D

# Size measured by tiles (16px)
@export var tile_size := Vector2i(2, 2) : set = set_tile_size

func _ready():
	# Scrolling animation
	if not Engine.is_editor_hint():
		var pos = $Sprite.global_position.x
		var tween = create_tween().set_loops()
		tween.tween_property($Sprite, "global_position:x", pos - 16, 1.0).from(pos)
		tween.play()

func set_tile_size(value):
	$CollisionShape.shape = $CollisionShape.shape.duplicate()

	# Update collider and sprite sizes
	tile_size = value
	tile_size.x = clampi(tile_size.x, 2, 40)
	tile_size.y = clampi(tile_size.y, 2, 24)

	$CollisionShape.position = tile_size * 8 + Vector2i(0, 4)
	$CollisionShape.shape.size = tile_size * 16 - Vector2i(0, 8)

	$Sprite.position = -Vector2.ONE
	$Sprite.size = (tile_size * 16 + Vector2i(18, 2)) * 4
