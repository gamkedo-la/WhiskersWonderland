extends StaticBody2D

@onready var collision_shape = $CollisionShape2D
@onready var crumble_timer = $CrumbleTimer
@onready var restart_timer = $RestartTimer
@onready var animation_player = $AnimationPlayer

func _on_trigger_entered(area):
	if area.is_in_group("player"):
		if crumble_timer.is_stopped() and restart_timer.is_stopped():
			animation_player.play("give_in")
			crumble_timer.start()

func _on_crumble():
	collision_shape.set_deferred("disabled", true)
	animation_player.play("destroy")
	restart_timer.start()

func _on_restart():
	collision_shape.set_deferred("disabled", false)
	animation_player.play("respawn")
