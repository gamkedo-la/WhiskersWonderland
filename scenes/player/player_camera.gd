extends Node2D

@export var enabled : bool = true

@export var move_on_x : bool = true
@export var move_on_y : bool = true

@export_range(0.0, 12.0, 0.25) var smoothing_left : float = 5.0
@export_range(0.0, 12.0, 0.25) var smoothing_right : float = 5.0
@export_range(0.0, 12.0, 0.25) var smoothing_up : float = 5.0
@export_range(0.0, 60.0, 0.25) var smoothing_down : float = 5.0
@onready var smoothing_up_copy = smoothing_up

@export var limit_left : float = -10000000
@export var limit_right : float = 10000000
@export var limit_top : float = -10000000
@export var limit_bottom : float = 10000000

@export var debug_mode : bool = true

enum CAMERA_MODE { PLATFORMING, CLIMBING }
var mode := CAMERA_MODE.PLATFORMING

var target : Vector2
@onready var viewport = get_viewport()
@onready var screen_size = viewport.get_visible_rect().size

func _ready():
	if not enabled:
		return
	Globals.camera = self
	viewport.canvas_transform.origin = to_camera_space(global_position)

func _draw():
	if debug_mode:
		draw_circle(to_local(target), 2.0, Color.RED)
		draw_circle(to_local(to_global_space(viewport.canvas_transform.origin)), 2.0, Color.BLUE)

func update(catchup: bool):
	if mode == CAMERA_MODE.PLATFORMING:
		smoothing_up = smoothing_up_copy if catchup else 0.0
	elif mode == CAMERA_MODE.CLIMBING:
		smoothing_up = 2.0

func platforming_mode():
	mode = CAMERA_MODE.PLATFORMING
	move_on_x = true

func climbing_mode():
	mode = CAMERA_MODE.CLIMBING
	move_on_x = false

func _process(delta):
	if not enabled:
		return
	
	var current = to_global_space(viewport.canvas_transform.origin)
	target = global_position
	var disp = target - current
	
	if debug_mode:
		print(current)
	
	if move_on_x:
		var speed = smoothing_left if disp.x < 0 else smoothing_right
		current.x += disp.x * speed * delta
		current.x = clamp(current.x, limit_left + screen_size.x/2, limit_right - screen_size.x/2)
		viewport.canvas_transform.origin.x = to_camera_space(current).x
	
	if move_on_y:
		var speed = smoothing_up if disp.y < 0 else smoothing_down
		current.y += disp.y * speed * delta
		current.y = clamp(current.y, limit_top + screen_size.y/2, limit_bottom - screen_size.y/2)
		viewport.canvas_transform.origin.y = to_camera_space(current).y
	
	queue_redraw()

func get_camera_position():
	return to_global_space(viewport.canvas_transform.origin)

func to_camera_space(pos: Vector2):
	return screen_size/2 - pos

func to_global_space(pos: Vector2):
	return -(pos - screen_size/2)
