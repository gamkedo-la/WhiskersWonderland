extends Node2D

@export var reset_size : bool = true
@export var particles : CPUParticles2D
@export var animation_player : AnimationPlayer

func _ready():
	if reset_size:
		global_rotation = 0
		global_scale = Vector2.ONE
	
	if particles:
		particles.finished.connect(_on_finished)
		particles.emitting = true
	
	if animation_player:
		animation_player.animation_finished.connect(_on_finished.unbind(1))

func _on_finished():
	queue_free()
