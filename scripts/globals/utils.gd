extends Node

# Generic
func approach(from: float, to: float, step: float):
	if from > to:
		return max(from - step, to)
	else:
		return min(from + step, to)

func timer(seconds: float):
	return get_tree().create_timer(seconds).timeout

# Geometry
func polar_to_cartesian(rad: float, theta: float) -> Vector2:
	return rad * Vector2(cos(theta), sin(theta))

func rotate_polygon(polygon: PackedVector2Array, angle: float) -> PackedVector2Array:
	var result = PackedVector2Array()
	for point in polygon:
		result.append(point.rotated(angle))
	return result

func get_bounding_box(polygon: PackedVector2Array) -> Rect2:
	var top_left = Vector2.ZERO
	var bottom_right = Vector2.ZERO
	for point in polygon:
		if point.x < top_left.x:
			top_left.x = point.x
		if point.x > bottom_right.x:
			bottom_right.x = point.x
		
		if point.y < top_left.y:
			top_left.y = point.y
		if point.y > bottom_right.y:
			bottom_right.y = point.y
	return Rect2(top_left, bottom_right - top_left)

# Tilemap
func get_tile_custom_data(tilemap: TileMap, global_pos: Vector2, layer_name: String, layer: int = 0):
	var local_pos = tilemap.to_local(global_pos)
	var cell_pos = Vector2i(tilemap.local_to_map(local_pos))
	var tile_data = tilemap.get_cell_tile_data(layer, cell_pos)
	if tile_data:
		return tile_data.get_custom_data(layer_name)
	return null

# Raycasts
func get_colliding_ray(raycast_group):
	for raycast in raycast_group.get_children():
		if raycast.is_colliding():
			return raycast
	return null

# Random
func rand_vec2() -> Vector2:
	return Vector2(randf(), randf())

func rand_sign() -> int:
	return pow(-1, randi() % 2)

func rand_dir() -> Vector2:
	return polar_to_cartesian(1.0, randf_range(0.0, TAU)).normalized()

func rand_bool() -> bool:
	return bool(randi() % 2)
