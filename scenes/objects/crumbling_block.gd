extends StaticBody2D

@onready var sprite = $placeholder
@onready var collision_shape = $CollisionShape2D
@onready var crumble_timer = $CrumbleTimer
@onready var restart_timer = $RestartTimer

var initial_color = Color("00cc99")

func _on_trigger_entered(area):
	if area.is_in_group("player"):
		if crumble_timer.is_stopped() and restart_timer.is_stopped():
			sprite.color = sprite.color.darkened(0.2)
			crumble_timer.start()

func _on_crumble():
	collision_shape.set_deferred("disabled", true)
	sprite.visible = false
	restart_timer.start()

func _on_restart():
	collision_shape.set_deferred("disabled", false)
	sprite.visible = true
	sprite.color = initial_color
