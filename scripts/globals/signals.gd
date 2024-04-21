extends Node

signal level_ready(level: BaseLevel)
signal item_collected(item: Collectible)
signal replay_ended()
signal player_died()
signal player_respawn()
signal player_reached_checkpoint(checkpoint)
