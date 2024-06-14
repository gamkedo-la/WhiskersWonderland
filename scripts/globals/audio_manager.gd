extends Node

# This is an autoload script that contains all of the sounds that needs to be played
# in the game!

# You can simple play any sound from here by using `AudioManager.audio_stream_name.play()`

# Add the audiostreamplayer references here

@export_group("Fox Sounds")
@export var fox_jump_sfx: AudioStreamPlayer
@export var fox_death_sfx: AudioStreamPlayer
@export var land_on_platform_sfx: AudioStreamPlayer
@export var stick_to_slime_sfx: AudioStreamPlayer
@export var land_on_grass_sfx: AudioStreamPlayer
@export var walk_on_sand_sfx: AudioStreamPlayer
@export var bounce_sfx: AudioStreamPlayer
@export var fox_respawn_sfx: AudioStreamPlayer
@export var walk_on_grass_sfx: AudioStreamPlayer

@export_group("World Sounds")
@export var crumbling_block_sfx: AudioStreamPlayer

@export_group("Other Sounds")
@export var quicksand_splash_sfx: AudioStreamPlayer
@export var robot_death_sfx: AudioStreamPlayer
@export var gem_pickup_sfx: AudioStreamPlayer

@export_group("Music")
@export var intro_theme : AudioStreamPlayer
@export var desert_theme: AudioStreamPlayer
