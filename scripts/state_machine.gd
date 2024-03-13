extends Node
class_name StateMachine

signal entered_state(state)
signal exited_state(state)
signal changed_state(previous, current)

var current_state : String
var states : Dictionary = {}

func initialize(initial_state: String):
	current_state = initial_state
	_enter(current_state)

func add_state(state_name: String, update_method: Callable = Callable(), enter_method: Callable = Callable(), exit_method: Callable = Callable()):
	states[state_name] = {
		"update": update_method,
		"enter": enter_method,
		"exit": exit_method
	}

func is_current(state_name: String) -> bool:
	return current_state == state_name

func update(delta: float):
	var method = states[current_state].update
	if not method.is_null():
		method.callv([delta])

func change_state(new_state: String):
	var previous_state = current_state
	_exit(previous_state)
	current_state = new_state
	_enter(new_state)
	changed_state.emit(previous_state, new_state)

func _enter(state_name: String):
	var method = states[state_name].enter
	if not method.is_null():
		method.call()
		entered_state.emit(state_name)

func _exit(state_name: String):
	var method = states[state_name].exit
	if not method.is_null():
		method.call()
		exited_state.emit(state_name)
