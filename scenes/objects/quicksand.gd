extends Area2D

@export var color := Color("995f32be")

var collision_shape

func _ready():
	for child in get_children():
		if child is CollisionShape2D:
			if child.shape is RectangleShape2D:
				collision_shape = child
			else:
				printerr("Quicksand object should use a RectangleShape2D as a trigger")

func _process(_delta):
	queue_redraw()

func _draw():
	var rect = collision_shape.shape.get_rect()
	rect.position += collision_shape.global_position - global_position
	draw_rect(rect, color)
