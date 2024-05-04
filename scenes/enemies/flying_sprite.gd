extends Sprite2D

@export var MOVE_SPEED := Vector2(75, -300)
@export var GRAVITY : float = 1000.0

var velocity : Vector2
var angular_velocity : float
var is_flying : bool = false

func _physics_process(delta):
	if not is_flying:
		return
	global_position += velocity * delta
	velocity.y += GRAVITY * delta
	rotation += angular_velocity * delta
	visible = not visible

func fly(node: Node):
	is_flying = true
	reparent(node, true)
	
	var variation = randf_range(0.5, 1.25)
	velocity = MOVE_SPEED * variation
	velocity.x *= Utils.rand_sign()
	angular_velocity = PI/3 * variation
	
	await Utils.timer(5.0)
	queue_free()
