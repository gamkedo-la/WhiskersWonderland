extends Node2D
class_name BaseLevel

const TITLE_SCREEN = "res://title_screen.tscn"

@onready var parallax_background = $World/ParallaxBackground
@onready var camera_bounds = $World/CameraBounds
@onready var tilemap = $World/TileMap
@onready var player = $World/player
@onready var animation_player = $AnimationPlayer

@onready var player_spawn_pos : Vector2 = player.global_position
var current_checkpoint : Node2D
var current_camera : Node2D

var purple_gems_count: int = 0
var purple_gems_collected: int = 0

func _ready():
	current_checkpoint = null
	player.tilemap = tilemap
	current_camera = Globals.camera if Globals.camera != null else get_viewport().get_camera_2d()
	set_camera_bounds()
	Signals.level_ready.emit(self)
	Signals.item_collected.connect(_on_item_collected)
	Signals.player_died.connect(_on_player_died)
	Signals.player_reached_checkpoint.connect(_on_player_reached_checkpoint)

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
	parallax_background.scroll_offset = -current_camera.get_camera_position() + current_camera.screen_size/2

	# Can only pause if player is alive
	if player.is_alive() and not player.is_demo:
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
	var respawn_pos = current_checkpoint.global_position if current_checkpoint else player_spawn_pos
	player.respawn(respawn_pos)

func _on_player_reached_checkpoint(checkpoint):
	if (current_checkpoint == null) or (current_checkpoint.number < checkpoint.number):
		current_checkpoint = checkpoint

func _on_player_died():
	Globals.pause()
	animation_player.play("player_died")

func register_collectible(item: Collectible):
	if item is PurpleGem:
		purple_gems_count += 1

func _on_item_collected(item: Collectible):
	if item is PurpleGem:
		purple_gems_collected += 1
		player.hud.update_gems(purple_gems_collected, item)

func _on_main_menu_pressed():
	Globals.resume()
	get_tree().change_scene_to_file(TITLE_SCREEN)

func _on_player_exited_level():
	Globals.pause()
	animation_player.play("level_complete")
