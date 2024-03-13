extends CharacterBody2D

const MOVE_SPEED : float = 80.0
const GRAVITY : float = 400.0

@onready var left_ray = $Raycasts/Left
@onready var right_ray = $Raycasts/Right

var move_direction : int = 1

func _ready():
	move_direction = 1

func _physics_process(delta):
	var left = left_ray.is_colliding()
	var right = right_ray.is_colliding()
	
	# Flip direction
	if not left and move_direction == -1:
		move_direction *= -1
	elif not right and move_direction == 1:
		move_direction *= -1
	
	velocity.x = MOVE_SPEED * move_direction
	velocity.y += GRAVITY * delta
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		if sign(normal.x) != 0:
			move_direction *= -1

func stomp():
	queue_free()
