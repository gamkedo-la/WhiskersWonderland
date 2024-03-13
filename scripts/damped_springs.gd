extends Node

var springs = []

func _physics_process(delta):
	for spring in springs:
		spring.update(delta)

func add_spring(damping_ratio: float, frequency: float) -> DampedSpring:
	var spring = DampedSpring.new(damping_ratio, frequency)
	springs.append(spring)
	return spring

class DampedSpring:
	var position : float
	var velocity : float
	var rest_pos : float
	
	var spring_const : float
	var damping_const : float
	
	var update_callback : Callable
	
	func _init(damping_ratio, frequency):
		position = 0.0
		velocity = 0.0
		rest_pos = 0.0
		spring_const = frequency * frequency
		damping_const = 2 * damping_ratio * frequency
		update_callback = Callable()
	
	func update(delta):
		var displacement = position - rest_pos
		var force = -damping_const * velocity - spring_const * displacement
		velocity += force * delta
		position += velocity * delta
		
		if not update_callback.is_null():
			update_callback.callv([position])
	
	func rest_at(_rest_pos: float) -> DampedSpring:
		position = _rest_pos
		rest_pos = _rest_pos
		return self
	
	func callback(_callback: Callable) -> DampedSpring:
		update_callback = _callback
		return self
