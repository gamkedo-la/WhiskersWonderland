extends Node2D

@onready var parallax_background = $World/ParallaxBackground
@onready var camera_bounds = $World/CameraBounds
@onready var tilemap = $World/TileMap
@onready var player = $World/player
@onready var animation_player = $AnimationPlayer

var player_spawn_pos : Vector2
var current_camera : Node2D

func _ready():
	player_spawn_pos = player.global_position
	player.tilemap = tilemap
	current_camera = Globals.camera if Globals.camera != null else get_viewport().get_camera_2d()
	set_camera_bounds()

func set_camera_bounds():
	camera_bounds.visible = false
	if current_camera != null and camera_bounds.polygon.size() > 0:
		var bounds_rect = Utils.get_bounding_box(camera_bounds.polygon)
		current_camera.limit_left = bounds_rect.position.x
		current_camera.limit_right = bounds_rect.position.x + bounds_rect.size.x
		current_camera.limit_top = bounds_rect.position.y
		current_camera.limit_bottom = bounds_rect.position.y + bounds_rect.size.y

func _process(_delta):
	# Calculate parallax offset
	parallax_background.scroll_offset = -current_camera.get_camera_position()
	
	# Can only pause if player is alive
	if player.is_alive():
		if Input.is_action_just_pressed("pause"):
			if Globals.is_paused():
				Globals.resume()
				animation_player.play("resume")
			else:
				Globals.pause()
				animation_player.play("pause")

func respawn_player():
	# This is called by "player_died" animation
	Globals.resume()
	player.respawn(player_spawn_pos)

func _on_player_died():
	Globals.pause()
	animation_player.play("player_died")
