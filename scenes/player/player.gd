extends CharacterBody2D

signal died

const INPUT_ACTIONS = ['jump']

const MOVING = 'moving'
const SLIDING = 'sliding'
const DEAD = 'dead'

@onready var visuals = $Visuals
@onready var dust_particles = $Visuals/Particles/Dust
@onready var dust_particles_delay = $Visuals/Particles/Dust/DelayTimer
@onready var slide_particles = $Visuals/Particles/Slide
@onready var slide_particles_timer = $Visuals/Particles/Slide/DelayTimer
@onready var ears = $Visuals/scale/root/CanvasGroup/Body/Head/Ears
@onready var tail = $Visuals/scale/root/CanvasGroup/Body/Tail
@onready var camera_target = $CameraTarget
@onready var camera = $CameraTarget/Camera
@onready var animation_player = $Visuals/AnimationPlayer
@onready var state_machine = $StateMachine
@onready var button_recorder = $ButtonRecorder

@onready var CAMERA_OFFSET = camera_target.position

@export var MAX_SPEED : float = 200.0

@export var GROUND_ACCELERATION : float = MAX_SPEED / 0.1
@export var GROUND_FRICTION : float = MAX_SPEED / 0.1
@export var AIR_ACCELERATION : float = MAX_SPEED / 0.1
@export var AIR_FRICTION : float = MAX_SPEED / 0.3

@export var JUMP_HEIGHT : float = 70.0
@export var JUMP_TIME : float = 0.32
@export var WALL_STICK_TIME : float = 0.1

@onready var JUMP_SPEED : float = -2*JUMP_HEIGHT/JUMP_TIME
@onready var GRAVITY : float = 2*JUMP_HEIGHT/(JUMP_TIME*JUMP_TIME)
@onready var MAX_FALL_SPEED : float = abs(JUMP_SPEED)
@export var WALL_SLIDE_SPEED : float = 80.0

@export var WALL_JUMP_DISTANCE := Vector2(25, 72)
var WALL_JUMP_SPEED : Vector2

@export var CORNER_CORRECTION : int = 8 # Up to 8 pixels

@export var JUMP_DAMP_FACTOR : float = 0.1
@export var JUMP_HANG_TIME : float = 0.033
@export var JUMP_COYOTE_TIME : float = 0.1
@export var JUMP_BUFFER_TIME : float = 0.1

@export var outline_color : Color = Color("#000000")
var recolor_outline_on_replay : bool = true

var tilemap : TileMap

var hang_timer : float = 0.0
var coyote_timer : float = 0.0
var jump_buffer : float = 0.0
var slide_timer : float = 0.0
var is_jumping : bool = false
var jump_damped : bool = false
var jumps_available : int = 1

var was_grounded : bool
var move_direction : Vector2
var last_direction : int = 1
var wall_direction : int = 0
var inputs := {}

func _ready():
	WALL_JUMP_SPEED.x = sqrt(2 * WALL_JUMP_DISTANCE.x * AIR_ACCELERATION)
	WALL_JUMP_SPEED.y = (GRAVITY * WALL_JUMP_SPEED.x / AIR_ACCELERATION) + (AIR_ACCELERATION * WALL_JUMP_DISTANCE.y * 0.5 / WALL_JUMP_SPEED.x)
	
	state_machine.add_state(MOVING, moving_update)
	state_machine.add_state(SLIDING, sliding_update, sliding_enter, sliding_exit)
	state_machine.add_state(DEAD)
	state_machine.initialize(MOVING)
	
	for action in INPUT_ACTIONS:
		inputs[action] = { "press": null, "hold": null, "released": null }
	
	visuals.set_outline_color(outline_color)
	button_recorder.set_listener(encode_inputs)
	button_recorder.init()

func encode_inputs() -> PackedByteArray:
	return PackedByteArray([
		move_direction.x, move_direction.y,
		inputs.jump.press, inputs.jump.hold, inputs.jump.released
	])

func replay_input(data: PackedByteArray):
	if data.is_empty():
		return
	move_direction = Vector2(data.decode_s8(0), data.decode_s8(1))
	inputs.jump.press = bool(data.decode_u8(2))
	inputs.jump.hold = bool(data.decode_u8(3))
	inputs.jump.released = bool(data.decode_u8(4))

func poll_input():
	move_direction.x = sign(Input.get_axis("left", "right"))
	move_direction.y = sign(Input.get_axis("up", "down"))
	
	for action in INPUT_ACTIONS:
		inputs[action].press = Input.is_action_just_pressed(action)
		inputs[action].hold = Input.is_action_pressed(action)
		inputs[action].released = Input.is_action_just_released(action)

func _process(_delta):
	if button_recorder.is_replaying():
		replay_input(button_recorder.get_current_frame())
	else:
		poll_input()
	
	if move_direction.x != 0:
		last_direction = move_direction.x
	
	if inputs.jump.press:
		jump_buffer = JUMP_BUFFER_TIME
	
	$DebugLabel.text = state_machine.current_state

func _physics_process(delta):
	state_machine.update(delta)

func moving_update(delta):
	# Update timers
	hang_timer -= delta
	coyote_timer -= delta
	jump_buffer -= delta
	
	# Update visuals
	visuals.scale.x = last_direction
	ears.scale.x = last_direction
	tail.scale.x = last_direction
	
	var is_grounded = is_on_floor()
	if is_grounded:
		coyote_timer = JUMP_COYOTE_TIME
		restore_jumps()
	
	# Land on ground, and manage dust particles
	if is_grounded and not was_grounded:
		land()
	dust_particles.emitting = is_grounded and dust_particles_delay.is_stopped() and move_direction.x != 0
	
	# Update camera's target position
	if move_direction.x != 0:
		camera_target.position = CAMERA_OFFSET * Vector2(move_direction.x, 1)
	
	# Dampen vertical velocity after releasing jump button
	if inputs.jump.released and not jump_damped and velocity.y < 0:
		velocity.y *= JUMP_DAMP_FACTOR
		hang_timer = 0.0
		jump_damped = true
	
	# Jump right after leaving a platform (coyote jump)
	if can_jump():
		if inputs.jump.press and coyote_timer > 0.0:
			jump()
	
	# If has jump buffer, jump immediately when landing on the ground
	if can_jump():
		if jump_buffer > 0.0 and inputs.jump.hold and is_grounded:
			jump()
	
	# Wall sliding
	if not is_grounded:
		update_wall_direction()
		
		# Check wall jump
		if wall_direction != 0 and jump_buffer > 0.0 and inputs.jump.hold:
			camera.update(true)
			wall_jump()
		
		# Check wall slide
		if velocity.y > 0:
			if wall_direction != 0 and move_direction.x == wall_direction:
				state_machine.change_state(SLIDING)
				move_and_slide()
				return
	
	# Horizontal movement
	var acceleration = GROUND_ACCELERATION if is_grounded else AIR_ACCELERATION
	var friction = GROUND_FRICTION if is_grounded else AIR_FRICTION
	
	if move_direction.x != 0:
		velocity.x = Utils.approach(velocity.x, MAX_SPEED * move_direction.x, acceleration * delta)
	else:
		velocity.x = Utils.approach(velocity.x, 0, friction * delta)
	
	# Vertical movement
	velocity.y += GRAVITY * delta
	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED
	
	# Manage jump additional time on air (hang time)
	if hang_timer > 0.0:
		velocity.y = 0.0
		if inputs.jump.released:
			hang_timer = 0.0
	
	if is_jumping and velocity.y > 0:
		is_jumping = false
		if inputs.jump.hold:
			hang_timer = JUMP_HANG_TIME
	
	# Edge nudging when jumping
	if velocity.y < 0:
		var motion = velocity * delta
		if test_move(global_transform, motion):
			for i in range(1, CORNER_CORRECTION + 1):
				var left_pos = global_transform.translated(Vector2.LEFT * i)
				var right_pos = global_transform.translated(Vector2.RIGHT * i)
				
				if not test_move(left_pos, motion):
					global_position.x -= i
					break
				elif not test_move(right_pos, motion):
					global_position.x += i
					break
	
	# Perform movement
	move_and_slide()
	was_grounded = is_grounded
	
	camera.update(is_grounded)
	
	# Play animations
	if is_on_floor():
		if move_direction.x != 0:
			animation_player.play("run")
		else:
			animation_player.play("idle")
	else:
		if velocity.y > 0:
			animation_player.play("fall")
	
	if stuck_inside_terrain():
		die()

func stuck_inside_terrain():
	var directions = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	for dir in directions:
		var pos = global_transform.translated(dir)
		if not test_move(pos, Vector2.ZERO):
			return false
	return true

func sliding_enter():
	velocity.y = 0
	slide_particles_timer.start()

func sliding_exit():
	slide_particles.emitting = false

func sliding_update(delta):
	slide_timer -= delta
	camera.update(true)
	
	visuals.scale.x = -wall_direction
	visuals.slide()
	slide_particles.emitting = slide_particles_timer.is_stopped()
	
	# Check for wall jump
	if inputs.jump.press:
		wall_jump()
		state_machine.change_state(MOVING)
		move_and_slide()
		return
	
	# Not touching wall anymore
	update_wall_direction()
	if wall_direction == 0:
		state_machine.change_state(MOVING)
		return
	
	# Reset slide timer
	if move_direction.x == wall_direction:
		slide_timer = WALL_STICK_TIME
	
	# Leave wall slide
	if slide_timer <= 0.0 or (move_direction.y == 1 and move_direction.x == 0) or is_on_floor():
		state_machine.change_state(MOVING)
		return
	
	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		velocity.x = 10 * wall_direction
		velocity.y = WALL_SLIDE_SPEED
	
	animation_player.play("slide")

func update_wall_direction():
	wall_direction = 0
	if is_on_wall():
		var collision = get_last_slide_collision()
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		
		if collider is StaticBody2D:
			wall_direction = -normal.x
		
		elif collider is TileMap:
			var tile_pos = collision.get_position() - normal
			if Utils.get_tile_custom_data(tilemap, tile_pos, "can_slide"):
				wall_direction = -normal.x
	
	if wall_direction != 0:
		jump_damped = false

func restore_jumps():
	jump_damped = false
	jumps_available = 1

func can_jump():
	return jumps_available > 0

func jump(jump_factor := 1.0):
	jump_buffer = 0.0
	is_jumping = true
	jumps_available = clamp(jumps_available - 1, 0, 1)
	velocity.y = JUMP_SPEED * jump_factor
	
	animation_player.play("jump")
	visuals.jump()

func wall_jump():
	jump_buffer = 0.0
	velocity.x = -wall_direction * WALL_JUMP_SPEED.x
	velocity.y = -WALL_JUMP_SPEED.y
	
	animation_player.play("jump")
	visuals.jump()

func land():
	visuals.land()
	dust_particles_delay.start()

func stomp(area):
	if area.is_in_group("enemy"):
		if velocity.y > 0 and not is_on_floor():
			var entity = area.get_parent()
			entity.stomp()
			jump(1.2)
			jump_damped = true

func is_alive() -> bool:
	return not state_machine.is_current(DEAD)

func die():
	process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.play("die")
	state_machine.change_state(DEAD)
	died.emit()

func respawn(at: Vector2):
	process_mode = Node.PROCESS_MODE_PAUSABLE
	global_position = at
	state_machine.change_state(MOVING)

### Callback functions
func _on_trigger_area_entered(area):
	if area.is_in_group("damage_zone"):
		die.call_deferred()

func _on_replay_started(data):
	global_position = data.player_position
	if recolor_outline_on_replay:
		visuals.set_outline_color(Color("#d00000"))

func _on_replay_ended(_data):
	print("Player stopped at %s" % [str(global_position)])
	if recolor_outline_on_replay:
		visuals.set_outline_color(outline_color)
