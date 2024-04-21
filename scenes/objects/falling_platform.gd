extends RigidBody2D

@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var _up_direction := Vector2.UP

func _ready():
	set_process(false)

func fall(up_direction):
	_up_direction = up_direction
	$AnimationPlayer.play("stepped_on")
	if $Timer.is_stopped():
		$Timer.start()
		visible_notifier.screen_exited.connect(_on_screen_exited)

func _on_timer_timeout():
	gravity_scale = 0.35 * -_up_direction.y
	await get_tree().create_timer(0.5).timeout
	set_process(true)

func _on_screen_exited() -> void:
	queue_free()
