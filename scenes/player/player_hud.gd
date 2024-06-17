extends CanvasLayer

@onready var coin_sprite = $Coin
@onready var coin_label = $CoinLabel
@onready var purple_gem_sprite = $PurpleGem
@onready var purple_gem_label = $PurpleGemLabel
@onready var animated_gem = $AnimatedGem

var coin_spring
var gem_spring

func _ready():
	coin_spring = DampedSpringSystem.add_spring(0.1, 25)
	gem_spring = DampedSpringSystem.add_spring(0.1, 25)

func _process(delta):
	coin_sprite.scale = Vector2.ONE + 0.5 * Vector2(coin_spring.position, -coin_spring.position)
	purple_gem_sprite.scale = Vector2.ONE + 0.5 * Vector2(gem_spring.position, -gem_spring.position)

func update_gems(amount: int, max_amount: int, item: Collectible):
	purple_gem_label.text = str(amount) + "/" + str(max_amount)
	animated_gem.position = to_hud_position(item.global_position)
	animated_gem.visible = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(animated_gem, "position", purple_gem_sprite.position, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func():
		animated_gem.visible = false
		gem_spring.position = -1
	)
	tween.play()

func update_coins(amount: int):
	coin_label.text = str(amount).pad_zeros(2)
	coin_spring.position = 1

func to_hud_position(pos: Vector2):
	return Globals.camera.screen_size / 2 + pos - Globals.camera.get_camera_position()
