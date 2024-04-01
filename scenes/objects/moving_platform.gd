@tool
extends Path2D

@export var paused : bool = true : set = set_paused
@export var loop : bool = false : set = set_loop
@export_range(0.1, 10.0, 0.1) var time_in_seconds : float = 1.0 : set = set_time_in_seconds
@export var is_solid : bool = true

func _ready():
	update_speed()
	update_animation()
	if not Engine.is_editor_hint():
		reparent_child_nodes()
		recalculate_collision_shape()
		if not is_solid:
			$Body/CollisionPolygon.one_way_collision = true
		self.paused = false

func recalculate_collision_shape():
	var collision_polygon = $Body/CollisionPolygon
	var rotated = Utils.rotate_polygon(collision_polygon.polygon, -collision_polygon.global_rotation)
	collision_polygon.polygon = rotated
	collision_polygon.global_rotation = 0.0

func reparent_child_nodes():
	var offset = curve.sample_baked(curve.get_baked_length() / 2)
	
	for child in get_children():
		if child != $Body and child != $PathFollow2D and child != $AnimationPlayer:
			child.reparent($Body, false)
			child.position -= offset

func _process(_delta):
	queue_redraw()

func _draw():
	var points = curve.get_baked_points()
	for i in points.size():
		var p1 = points[i]
		var p2 = points[(i+1)%points.size()]
		draw_line(p1, p2, Color.DIM_GRAY, 0.5, true)

func update_speed():
	$AnimationPlayer.speed_scale = 1.0 / time_in_seconds

func update_animation():
	if paused:
		$AnimationPlayer.stop()
		$PathFollow2D.progress_ratio = 0.0 if loop else 0.5
	else:
		var anim_name = "looped" if loop else "back_and_forth"
		$AnimationPlayer.play(anim_name)

func set_paused(value: bool):
	paused = value
	if not Engine.is_editor_hint():
		paused = false
	update_animation()

func set_loop(value: bool):
	loop = value
	if Engine.is_editor_hint():
		update_animation()

func set_time_in_seconds(value: float):
	time_in_seconds = value
	if Engine.is_editor_hint():
		update_speed()
