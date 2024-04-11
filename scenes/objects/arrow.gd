extends CharacterBody2D

const MOVE_SPEED : float = 240.0

func shoot(direction: Vector2):
	velocity = direction * MOVE_SPEED

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		destroy()

func _on_hitbox_area_entered(area):
	if area.is_in_group("hurtbox") and area.is_in_group("player"):
		destroy()

func destroy():
	queue_free()
