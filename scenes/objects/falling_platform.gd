extends RigidBody2D


func _ready():
	set_process(false)
	

func _process(_delta):
	var player_y = get_tree().get_nodes_in_group("player").front().global_position.y
	if global_position.y > player_y + get_viewport().get_visible_rect().size.y:
		queue_free()
		set_process(false)


func fall():
	if $Timer.is_stopped():
		$Timer.start()


func _on_timer_timeout():
	gravity_scale = 0.5
	
	await get_tree().create_timer(0.5).timeout
	collision_layer = 0
	collision_mask = 0
	
	set_process(true)
