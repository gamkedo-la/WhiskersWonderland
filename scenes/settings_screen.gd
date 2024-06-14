extends Node2D

signal main_menu

@onready var sample_music = $SampleMusic
@onready var sample_sound = $SampleSound

var music_volume : float = 1.0
var sound_volume : float = 1.0

var playback_progress = 0.0

func change_music_volume(new_volume: float):
	music_volume = new_volume / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))

func change_sound_volume(new_volume: float):
	sound_volume = new_volume / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear_to_db(sound_volume))

func _on_music_slider_drag_started():
	# sample_music.play(playback_progress)
	pass

func _on_music_slider_drag_ended(value_changed):
	playback_progress = sample_music.get_playback_position()
	# sample_music.stop()
	pass

func _on_sound_slider_drag_ended(value_changed):
	# sample_sound.play()
	pass

func _on_main_menu_button_pressed():
	main_menu.emit()
