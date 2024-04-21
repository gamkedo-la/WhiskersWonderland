extends Marker2D

## When the player respawns, all the children of this node will also be respawned.
@export var respawn_with_player := true
var spawn_scenes : Array[PackedScene]

func _ready() -> void:
	for child in get_children():
		var packed_scene := PackedScene.new()
		packed_scene.pack(child)
		spawn_scenes.append(packed_scene)

	if respawn_with_player:
		Signals.player_respawn.connect(_spawn)

func _spawn() -> void:
	for child in get_children():
		child.visible = false
		child.queue_free()

	for scene in spawn_scenes:
		var spawn := scene.instantiate()
		add_child.call_deferred(spawn)
