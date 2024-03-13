extends Line2D
class_name PointChain2D

@export var anchor_node : Node2D
@export var sprites : Node2D

@onready var num_points = points.size()
@onready var anchor_offset = points[0]

func _process(_delta):
	# Apply position and rotation to sprites
	for i in num_points-1:
		var sprite = sprites.get_child(i)
		sprite.global_position = points[i]
		sprite.rotation = points[i].angle_to_point(points[i+1]) + PI

func _physics_process(_delta):
	# If anchor node is configured, set first point's target and update
	if anchor_node != null:
		update(anchor_node.global_position)

func update(target: Vector2):
	target += anchor_offset
	
	# Move the chain
	for i in num_points-1:
		var result = reach(points[i], points[i+1], target)
		points[i] = result[0]
		target = result[1]
	points[-1] = target

func reach(head, tail, target: Vector2):
	var c_length = (tail - head).length()
	var s_delta = (tail - target)
	var scaling = c_length / s_delta.length()
	
	# return [new head, new tail]
	return [target, target + s_delta * scaling]
