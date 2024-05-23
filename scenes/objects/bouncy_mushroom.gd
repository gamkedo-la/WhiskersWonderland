extends Area2D

@onready var visuals = $Visuals

var spring

func _ready():
	spring = DampedSpringSystem.add_spring(0.25, 20.0)

func _process(delta):
	visuals.scale = Vector2.ONE + 0.5 * Vector2(spring.position, -spring.position)

func bounce():
	spring.position = 1.0
