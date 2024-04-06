extends Node

# This is an autoload script that contains all of the sounds that needs to be played
# in the game!

# You can simple play any sound from here by using `AudioManager.audio_stream_name.play()`

# Add the audiostreamplayer references here
@onready var gem_pickup_sfx: AudioStreamPlayer = $GemPickupSFX
@onready var fox_jump_sfx: AudioStreamPlayer = $FoxJumpSFX
@onready var fox_death_sfx: AudioStreamPlayer = $FoxDeathSFX
@onready var land_on_grass_sfx: AudioStreamPlayer = $LandOnGrassSFX
@onready var land_on_platform_sfx: AudioStreamPlayer = $LandOnPlatformSFX
