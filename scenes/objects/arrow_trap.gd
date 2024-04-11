extends Node2D

@export var delay : float = 0.0

@onready var shoot_timer = $ShootTimer

const ARROW_OBJECT = preload("res://scenes/objects/arrow.tscn")

func _ready():
	if delay > 0.0:
		await Utils.timer(delay)
	shoot_timer.start()

func _on_shoot_timer_timeout():
	var arrow = ARROW_OBJECT.instantiate()
	add_child(arrow)
	var direction = Vector2.RIGHT.rotated(global_rotation)
	arrow.position = -24.0 * direction
	arrow.shoot(direction)
