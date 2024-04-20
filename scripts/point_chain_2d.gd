extends Line2D
class_name PointChain2D

@export var anchor_node : Node2D
@export var sprites : Node2D

@onready var num_points = points.size()
@onready var anchor_offset = points[0]

var y_rotated := false

func _process(_delta):
	# Apply position and rotation to sprites
	for i in num_points-1:
		var sprite = sprites.get_child(i)
		sprite.global_position = points[i]
		var point_from := points[i]
		var point_to := points[i+1]
		if y_rotated:
			var tmp_y = point_from.y
			point_from.y = point_to.y
			point_to.y = tmp_y
		sprite.rotation = point_from.angle_to_point(point_to) + PI

func _physics_process(_delta):
	# If anchor node is configured, set first point's target and update
	if anchor_node != null:
		update(anchor_node.global_position)

func update(target: Vector2):
	target += anchor_offset * Vector2(1.0, -1.0 if y_rotated else 1.0)

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
