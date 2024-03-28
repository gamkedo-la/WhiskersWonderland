extends TileMap

func _use_tile_data_runtime_update(layer: int, _coords: Vector2i):
	return layer != 0

func _tile_data_runtime_update(_layer: int, _coords: Vector2i, tile_data: TileData) -> void:
	tile_data.set_collision_polygons_count(0, 0)
