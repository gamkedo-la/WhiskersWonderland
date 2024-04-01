extends Area2D
class_name Collectible


func _ready() -> void:
	Signals.level_ready.connect(func(level): level.register_collectible(self))
	area_entered.connect(on_area_entered)

func on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") and visible:
		collect()

func collect() -> void:
	visible = false
	Signals.item_collected.emit(self)
	AudioManager.gem_pickup_sfx.play()
	queue_free()
