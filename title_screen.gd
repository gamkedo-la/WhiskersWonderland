extends Node2D

const GAME_SCENE = preload("res://scenes/game.tscn")
const TITLE_LEVEL = preload("res://scenes/levels/title_level.tscn")

@onready var animation_player = $AnimationPlayer

var title_level

func _ready():
	animation_player.play("default")
	load_title_level()
	Signals.replay_ended.connect(_on_replay_ended)

func _process(_delta):
	if Input.is_action_just_pressed("start"):
		get_tree().change_scene_to_packed(GAME_SCENE)

func load_title_level():
	if title_level:
		title_level.queue_free()
	title_level = TITLE_LEVEL.instantiate()
	add_child(title_level)

func _on_replay_ended():
	animation_player.play("transition")
