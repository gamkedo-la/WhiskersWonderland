extends RigidBody2D

func _ready():
	set_process(false)

func _process(_delta):
	if global_position.y > Globals.player_pos.y + get_viewport().get_visible_rect().size.y:
		queue_free()

func fall():
	$AnimationPlayer.play("stepped_on")
	if $Timer.is_stopped():
		$Timer.start()

func _on_timer_timeout():
	gravity_scale = 0.35
	await get_tree().create_timer(0.5).timeout
	set_process(true)
