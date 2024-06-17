extends Node2D

signal main_menu

func _ready():
	$MusicSlider.value = Globals.music_volume * 100.0
	$SoundSlider.value = Globals.sound_volume * 100.0

func change_music_volume(new_volume: float):
	Globals.music_volume = new_volume / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Globals.music_volume))

func change_sound_volume(new_volume: float):
	Globals.sound_volume = new_volume / 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear_to_db(Globals.sound_volume))

func _on_main_menu_button_pressed():
	main_menu.emit()
