extends Node2D

const ARROW_OBJECT = preload("res://scenes/objects/arrow.tscn")

func _on_shoot_timer_timeout():
	var arrow = ARROW_OBJECT.instantiate()
	add_child(arrow)
	var direction = Vector2.RIGHT.rotated(global_rotation)
	arrow.position = -24.0 * direction
	arrow.shoot(direction)
