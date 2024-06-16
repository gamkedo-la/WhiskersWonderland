extends CharacterBody2D

signal exited_level

const INPUT_ACTIONS = ['jump', 'use_gem']

const MOVING = 'moving'
const SLIDING = 'sliding'
const IN_SLIME = 'in_slime'
const DEAD = 'dead'

@onready var hud = $HUD
@onready var visuals = $Visuals
@onready var dust_particles = $Visuals/Particles/Dust
@onready var dust_particles_delay = $Visuals/Particles/Dust/DelayTimer
@onready var slide_particles = $Visuals/Particles/Slide
@onready var slide_particles_timer = $Visuals/Particles/Slide/DelayTimer
@onready var ears = $Visuals/scale/root/CanvasGroup/Body/Head/Ears
@onready var tail = $Visuals/scale/root/CanvasGroup/Body/Tail
@onready var tail_points: PointChain2D = $Node/TailPoints
@onready var camera_target = $CameraTarget
@onready var camera = $CameraTarget/Camera
@onready var ground_raycast = $GroundRaycast
@onready var areas: Node2D = $Areas
@onready var trigger = $Areas/Trigger
@onready var animation_player = $Visuals/AnimationPlayer
@onready var wall_jump_timer = $Timers/WallJumpTimer
@onready var state_machine = $StateMachine
@onready var button_recorder = $ButtonRecorder

@onready var CAMERA_OFFSET = camera_target.position

@export var is_demo : bool = false

@export var MAX_SPEED : float = 180.0

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
@export var WALL_SLIDE_SPEED : float = 60.0

@export var QUICKSAND_MOVE_SPEED : float = 120.0
@export var QUICKSAND_FALL_SPEED : float = 40.0
@export var QUICKSAND_JUMP_FACTOR : float = 0.6

@export var WALL_JUMP_DISTANCE := Vector2(25, 72)
var WALL_JUMP_SPEED : Vector2

@export var CORNER_CORRECTION : int = 12 # Up to 12 pixels

@export var JUMP_DAMP_FACTOR : float = 0.1
@export var JUMP_HANG_TIME : float = 0.016
@export var JUMP_COYOTE_TIME : float = 0.066
@export var JUMP_BUFFER_TIME : float = 0.1

@onready var coins : int = 0

var tilemap : TileMap
var last_collision : KinematicCollision2D

var hang_timer : float = 0.0
var coyote_timer : float = 0.0
var jump_buffer : float = 0.0
var slide_timer : float = 0.0
var is_jumping : bool = false
var jump_damped : bool = false
var jumps_available : int = 1

var tracking_slime: Area2D
var previous_slime_position : Vector2
var gravity_flipped := false

var was_in_quicksand : bool
var was_grounded : bool
var move_direction : Vector2
var last_direction : int = 1
var wall_direction : int = 0
var inputs := {}

var is_falling: bool:
	get:
		return (velocity.y > 0) if up_direction == Vector2.UP else (velocity.y < 0)
var is_raising: bool:
	get:
		return (velocity.y < 0) if up_direction == Vector2.UP else (velocity.y > 0)

func _ready():
	WALL_JUMP_SPEED.x = sqrt(2 * WALL_JUMP_DISTANCE.x * AIR_ACCELERATION)
	WALL_JUMP_SPEED.y = (GRAVITY * WALL_JUMP_SPEED.x / AIR_ACCELERATION) + (AIR_ACCELERATION * WALL_JUMP_DISTANCE.y * 0.5 / WALL_JUMP_SPEED.x)

	state_machine.add_state(MOVING, moving_update)
	state_machine.add_state(SLIDING, sliding_update, sliding_enter, sliding_exit)
	state_machine.add_state(IN_SLIME, in_slime_update)
	state_machine.add_state(DEAD)
	state_machine.initialize(MOVING)

	for action in INPUT_ACTIONS:
		inputs[action] = { "press": null, "hold": null, "released": null }

	visuals.set_outline_color(Color.BLACK)
	Debug.kill_player.connect(die)

	if is_demo:
		hud.visible = false
		button_recorder.mode = ButtonRecorder.ButtonRecorderMode.REPLAY
		button_recorder.replay_file_path = "res://scenes/levels/demo.replay"
	button_recorder.set_listener(encode_inputs)
	button_recorder.init()

	Signals.item_collected.connect(_on_item_collected)

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
	elif not is_demo:
		poll_input()

	if move_direction.x != 0:
		last_direction = move_direction.x

	if inputs.jump.press:
		jump_buffer = JUMP_BUFFER_TIME

	$DebugLabel.text = state_machine.current_state

func _physics_process(delta):
	var collision = get_last_slide_collision()
	last_collision = collision if collision else last_collision

	state_machine.update(delta)
	Globals.player_pos = global_position

func moving_update(delta):
	# Update timers
	hang_timer -= delta
	coyote_timer -= delta
	jump_buffer -= delta

	# Update visuals
	visuals.scale.x = last_direction * -up_direction.y
	ears.scale.x = last_direction
	tail.scale.x = last_direction

	var in_quicksand = is_in_quicksand()
	z_index = -2 if in_quicksand else 0
	
	if was_in_quicksand != in_quicksand:
		visuals.spawn_quicksand_splash()
		if in_quicksand:
			AudioManager.quicksand_splash_sfx.play()

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
	
	if is_grounded:
		camera.platforming_mode()

	# Dampen vertical velocity after releasing jump button
	if inputs.jump.released and not jump_damped and is_raising:
		velocity.y *= JUMP_DAMP_FACTOR
		hang_timer = 0.0
		jump_damped = true

	# Can always jump in quicksand
	if in_quicksand:
		if inputs.jump.press:
			jump(QUICKSAND_JUMP_FACTOR, false)

	# Jump right after leaving a platform (coyote jump)
	if can_jump():
		if inputs.jump.press and coyote_timer > 0.0:
			jump()

	# If has jump buffer, jump immediately when landing on the ground
	if can_jump():
		if jump_buffer > 0.0 and inputs.jump.hold and is_grounded:
			jump()

	# Wall sliding
	if not is_grounded and not in_quicksand:
		update_wall_direction()

		# Check wall jump
		if wall_direction != 0 and jump_buffer > 0.0 and inputs.jump.hold:
			camera.update(true)
			wall_jump()

		# Check wall slide
		if is_falling:
			if wall_direction != 0 and move_direction.x == wall_direction:
				state_machine.change_state(SLIDING)
				move_and_slide()
				return

	# Horizontal movement
	var acceleration = GROUND_ACCELERATION if is_grounded else AIR_ACCELERATION
	var friction = GROUND_FRICTION if is_grounded else AIR_FRICTION
	var run_speed = MAX_SPEED
	var fall_speed = MAX_FALL_SPEED

	if in_quicksand:
		run_speed = QUICKSAND_MOVE_SPEED
		fall_speed = QUICKSAND_FALL_SPEED

	fall_speed *= -up_direction.y

	if move_direction.x != 0:
		velocity.x = Utils.approach(velocity.x, run_speed * move_direction.x, acceleration * delta)
	else:
		velocity.x = Utils.approach(velocity.x, 0, friction * delta)

	# Vertical movement
	velocity.y += GRAVITY * delta * -up_direction.y
	if sign(velocity.y) == sign(fall_speed) and abs(velocity.y) > abs(fall_speed):
		velocity.y = fall_speed

	# Manage jump additional time on air (hang time)
	if hang_timer > 0.0:
		velocity.y = 0.0
		if inputs.jump.released:
			hang_timer = 0.0

	if is_jumping and is_falling:
		is_jumping = false
		if inputs.jump.hold:
			hang_timer = JUMP_HANG_TIME

	# Edge nudging when jumping
	if is_raising:
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
	
	# Modify velocity if on moving platform
	if is_grounded:
		if move_direction.x != 0 and abs(get_platform_velocity().x) > 0:
			if sign(move_direction.x) != sign(get_platform_velocity().x):
				global_position.x -= get_platform_velocity().x * delta

	# Perform movement
	move_and_slide()
	was_grounded = is_grounded
	was_in_quicksand = is_in_quicksand()

	camera.update(is_grounded)

	# Play animations
	if is_on_floor():
		if move_direction.x != 0:
			animation_player.play("run")
		else:
			animation_player.play("idle")
	else:
		if is_falling:
			animation_player.play("fall")

	if stuck_inside_terrain():
		die()

func stuck_inside_terrain() -> bool:
	var directions = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	for dir in directions:
		var pos = global_transform.translated(dir)
		if not test_move(pos, Vector2.ZERO):
			return false
	return true

func get_trigger(trigger_group: String) -> Area2D:
	for area in trigger.get_overlapping_areas():
		if area.is_in_group(trigger_group):
			return area
	return null

func is_in_trigger(trigger_group: String) -> bool:
	return get_trigger(trigger_group) != null

func is_in_quicksand() -> bool:
	return is_in_trigger("quicksand")

func is_in_slime() -> bool:
	return is_in_trigger("slime")

func is_on_sand():
	pass

func sliding_enter():
	velocity.y = 0
	slide_particles_timer.start()

func sliding_exit():
	slide_particles.emitting = false

func sliding_update(delta):
	slide_timer -= delta
	camera.update(true)

	visuals.scale.x = -wall_direction * -up_direction.y
	visuals.slide()
	if slide_particles_timer.is_stopped() and not slide_particles.emitting:
		slide_particles.restart()
		slide_particles.emitting = true

	if is_in_slime():
		track_slime(get_trigger("slime"))
		move_and_slide()
		return

	if is_in_quicksand():
		state_machine.change_state(MOVING)
		move_and_slide()
		return

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
		velocity.y = WALL_SLIDE_SPEED * -up_direction.y

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

func track_slime(slime: Area2D):
	tracking_slime = slime
	tracking_slime.splash(global_position.y - 14.5)
	previous_slime_position = slime.global_position
	state_machine.change_state(IN_SLIME)

func in_slime_update(_delta):
	z_index = -2

	if inputs.jump.press:
		wall_jump(false)
		state_machine.change_state(MOVING)
		move_and_slide()
		return

	var slime_movement := tracking_slime.global_position - previous_slime_position
	global_position += slime_movement
	previous_slime_position = tracking_slime.global_position

	animation_player.play("slide")

func restore_jumps():
	jump_damped = false
	jumps_available = 1

func can_jump():
	return jumps_available > 0

func jump(jump_factor := 1.0, spawn_dust: bool = true):
	jump_buffer = 0.0
	is_jumping = true
	jumps_available = clamp(jumps_available - 1, 0, 1)
	velocity.y = JUMP_SPEED * jump_factor * -up_direction.y

	animation_player.play("jump")
	if spawn_dust:
		visuals.spawn_jump_dust()
	visuals.jump()
	AudioManager.fox_jump_sfx.play()

func wall_jump(spawn_dust: bool = true):
	jump_buffer = 0.0
	velocity.x = -wall_direction * WALL_JUMP_SPEED.x
	velocity.y = -WALL_JUMP_SPEED.y * -up_direction.y
	camera.climbing_mode()
	wall_jump_timer.start()

	animation_player.play("jump")
	if spawn_dust:
		visuals.spawn_wall_jump_dust()
	visuals.jump()
	AudioManager.fox_jump_sfx.play()

func land():
	visuals.land()
	dust_particles_delay.start()
	AudioManager.land_on_platform_sfx.play()

func is_alive() -> bool:
	return not state_machine.is_current(DEAD)

func die():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visuals.on_death()
	animation_player.play("die")
	state_machine.change_state(DEAD)
	Signals.player_died.emit()
	AudioManager.fox_death_sfx.play()

func respawn(at: Vector2):
	Signals.player_respawn.emit()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	global_position = at
	state_machine.change_state(MOVING)
	if gravity_flipped:
		_flip_gravity()
	await Utils.timer(0.5)
	AudioManager.fox_respawn_sfx.play()

func play_step_sfx():
	if ground_raycast.is_colliding():
		var at = ground_raycast.get_collision_point()
		var terrain_type = Utils.get_tile_custom_data(tilemap, at, "terrain_type")
		
		match terrain_type:
			"sand":
				AudioManager.walk_on_sand_sfx.play()
			"grass":
				AudioManager.walk_on_grass_sfx.play()
			#"stone":
				#break

### Callback functions
func _on_trigger_area_entered(area):
	if area.is_in_group("damage_zone"):
		die()

	if area.is_in_group("checkpoint"):
		Signals.player_reached_checkpoint.emit(area)
	
	if area.is_in_group("bouncy_mushroom"):
		if is_falling and not is_on_floor():
			velocity.x = 0
			AudioManager.bounce_sfx.play()
			jump(1.75, false)
			jump_damped = true
			area.bounce()
			camera.climbing_mode()

	if area.is_in_group("falling_platform"):
		# Platform can only fall if player is above it
		if (
			(up_direction == Vector2.UP and global_position.y < area.global_position.y)
			or (up_direction == Vector2.DOWN and global_position.y > area.global_position.y)
		):
			var entity = area.get_parent()
			entity.fall(up_direction)
	
	if area.is_in_group("level_exit"):
		exited_level.emit()

func _on_hitbox_area_entered(area):
	# Stomp enemy
	if area.is_in_group("hurtbox") and area.is_in_group("enemy"):
		if is_falling and not is_on_floor():
			var entity = area.get_parent()
			entity.stomp()
			visuals.spawn_impact_effect(global_position)
			jump(1.2, false)
			jump_damped = true

func _on_hurtbox_area_entered(area):
	if area.is_in_group("hitbox") and not area.is_in_group("player"):
		die()

func _on_replay_started(data):
	global_position = data.player_position

func _on_replay_ended(_data):
	if Globals.debug_mode:
		print("Player stopped at %s" % [str(global_position)])

func _on_wall_jump_timer_timeout():
	camera.move_on_x = true

func _on_item_collected(item: Collectible) -> void:
	if item is GravityGem:
		_flip_gravity()
		velocity.y = 0
	if item is Coin:
		coins += 1
		hud.update_coins(coins)

func _flip_gravity(force: bool = false) -> bool:
	gravity_flipped = not gravity_flipped
	visuals.rotation += PI
	visuals.scale.x *= -1.0
	up_direction *= -1.0
	tail_points.y_rotated = not tail_points.y_rotated
	areas.rotation += PI
	return true
