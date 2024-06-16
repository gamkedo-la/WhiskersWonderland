extends Node
class_name ButtonRecorder

signal replay_started(data)
signal replay_ended(data)

const REPLAY_FOLDER = "user://replays"
const FILE_EXTENSION = ".replay"

enum ButtonRecorderMode { NONE, RECORDING, REPLAY }

@export var mode : ButtonRecorderMode = ButtonRecorderMode.NONE
@export_global_file("*" + FILE_EXTENSION) var replay_file_path : String

var listener : Callable
var data : ReplayFile

func init():
	Debug.reloaded_scene.connect(_on_reload_scene)
	data = ReplayFile.new(get_parent().global_position, Globals.current_level)
	
	# Create "replays" directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(REPLAY_FOLDER):
		DirAccess.make_dir_absolute(REPLAY_FOLDER)
	
	if mode == ButtonRecorderMode.REPLAY:
		load_replay_file()

func set_listener(callable: Callable):
	listener = callable

func _physics_process(_delta):
	if mode == ButtonRecorderMode.REPLAY:
		data.frame_index += 1
		if data.has_replay_ended():
			if Globals.debug_mode:
				print("Replay ended")
			replay_ended.emit(data)
			Signals.replay_ended.emit()
			mode = ButtonRecorderMode.NONE
	
	if mode != ButtonRecorderMode.RECORDING or listener.is_null():
		return
	
	# Record datas for this frame
	var frame_data = listener.call()
	data.inputs.append(frame_data)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_recording()

func save_recording():
	if mode == ButtonRecorderMode.RECORDING and not data.inputs.is_empty():
		var datetime = Time.get_datetime_string_from_system().replace(":", "-")
		var filename = datetime + '_v' + Debug.BUILD_VERSION + FILE_EXTENSION
		var file = FileAccess.open(REPLAY_FOLDER + '/' + filename, FileAccess.WRITE_READ)
		file.store_var(data.serialize())
		file.close()
		if Globals.debug_mode:
			print("Saved session to file %s" % [filename])

func load_replay_file():
	var filepath = replay_file_path
	if filepath.is_empty():
		var dir = DirAccess.open(REPLAY_FOLDER)
		var files = dir.get_files()
		
		if files.is_empty():
			mode = ButtonRecorderMode.NONE
			if Globals.debug_mode:
				print("No replay files found")
			return
		
		# Play most recent file
		replay_file_path = files[-1]
		filepath = REPLAY_FOLDER + '/' + replay_file_path
	
	var file = FileAccess.open(filepath, FileAccess.READ)
	data = ReplayFile.load_from_file(file)
	if Globals.debug_mode:
		if data.build_version != Debug.BUILD_VERSION:
			print("Replay build version (v%s) is different from current build" % [data.build_version])
		if data.current_level != Globals.current_level:
			print("Replay level (%s) is different from current level being played" % [str(data.current_level)])
	
	replay_started.emit(data)
	if Globals.debug_mode:
		print("Replay started (%s)" % [ProjectSettings.globalize_path(filepath)])

func _on_reload_scene():
	save_recording()
	data.inputs = []

### Helper methods
func is_replaying():
	return mode == ButtonRecorderMode.REPLAY

func get_current_frame():
	return data.get_current_frame()

class ReplayFile:
	var player_position : Vector2
	var current_level : int
	var inputs
	var build_version : String
	
	var frame_index : int
	
	func _init(_player_pos: Vector2, _level):
		player_position = _player_pos
		current_level = _level
		inputs = []
		frame_index = 0
		build_version = Debug.BUILD_VERSION
	
	func has_replay_ended() -> bool:
		return inputs.size() > 0 and frame_index >= inputs.size()
	
	func get_current_frame():
		if frame_index < inputs.size():
			return inputs[frame_index]
		return PackedByteArray()
	
	func serialize():
		return {
			"player_position": player_position,
			"current_level": current_level,
			"inputs": inputs,
			"build_version": build_version
		}
	
	static func load_from_file(file: FileAccess) -> ReplayFile:
		var data = file.get_var(true)
		var replay_file = ReplayFile.new(data["player_position"], data["current_level"])
		replay_file.inputs = data["inputs"]
		replay_file.build_version = data["build_version"]
		return replay_file
