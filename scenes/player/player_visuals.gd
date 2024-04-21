extends Node2D

const JUMP_DUST_EFFECT = preload("res://scenes/effects/jump_dust.tscn")
const LAND_DUST_EFFECT = preload("res://scenes/effects/land_dust.tscn")
const IMPACT_EFFECT = preload("res://scenes/effects/impact.tscn")

@onready var player = get_parent()
@onready var root = $scale/root
@onready var canvas_group = $scale/root/CanvasGroup
@onready var ear_l = $scale/root/CanvasGroup/Body/Head/Ears/EarL
@onready var ear_r = $scale/root/CanvasGroup/Body/Head/Ears/EarR

var scale_tween

var earL_spring
var earR_spring

func _ready():
	earL_spring = DampedSpringSystem.add_spring(0.2, 15.0)
	earR_spring = DampedSpringSystem.add_spring(0.2, 15.0)

func _process(_delta):
	# Apply spring values to Ear rotation
	ear_l.rotation = deg_to_rad(30.0) * earL_spring.position
	ear_r.rotation = deg_to_rad(30.0) * earR_spring.position

func _physics_process(_delta):
	var velocity = player.velocity
	var move_direction = player.move_direction

	# Apply movement when running
	if move_direction.x != 0 and player.is_on_floor():
		earL_spring.velocity = -3 * sign(velocity.x)
		earR_spring.velocity = -3 * sign(velocity.x)

func slide():
	# Apply movement to ears when sliding
	var wall_direction = get_parent().wall_direction
	earL_spring.velocity = 1.5 * wall_direction
	earR_spring.velocity = 1.5 * wall_direction

func jump():
	# Bounce ears
	earL_spring.position = -0.3
	earR_spring.position = 0.3

	# Stretch sprite when jumping
	root.scale = Vector2(0.75, 1.25)
	if scale_tween: scale_tween.stop()
	scale_tween = get_tree().create_tween()
	scale_tween.tween_property(root, "scale", Vector2.ONE, 0.2)
	scale_tween.play()

func land():
	spawn_land_dust()

	# Bounce ears
	earL_spring.position = 0.3
	earR_spring.position = -0.3

	# Squash sprite when landing
	root.scale = Vector2(1.25, 0.75)
	if scale_tween: scale_tween.stop()
	scale_tween = get_tree().create_tween()
	scale_tween.tween_property(root, "scale", Vector2.ONE, 0.1)
	scale_tween.play()

func spawn_impact_effect(at):
	var effect = IMPACT_EFFECT.instantiate()
	player.get_parent().add_child(effect)
	effect.global_position = at

func spawn_jump_dust():
	var effect = JUMP_DUST_EFFECT.instantiate()
	player.last_collision.get_collider().add_child(effect)
	effect.global_position = player.global_position - Vector2(0, 4)

func spawn_wall_jump_dust():
	var effect = JUMP_DUST_EFFECT.instantiate()
	player.last_collision.get_collider().add_child(effect)
	effect.global_position = player.last_collision.get_position() + Vector2(4 * player.wall_direction, 0)

func spawn_land_dust():
	var effect = LAND_DUST_EFFECT.instantiate()
	player.last_collision.get_collider().add_child(effect)
	effect.global_position = player.global_position

func set_outline_color(color: Color):
	canvas_group.get_material().set_shader_parameter("outline_color", color)
