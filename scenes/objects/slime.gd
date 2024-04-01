@tool
extends Node2D

@export var size := Vector2(16, 32)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	_update_size()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_size()

func _update_size() -> void:
	collision_shape_2d.shape.size = size
	#sprite.scale = size
	#sprite.position = -size / 2.0
