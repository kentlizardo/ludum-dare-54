extends Node2D

@export
var actor_sprite : Sprite2D
@onready
var actor_sprite_bind : SpriteBind = SpriteBind.new(actor_sprite)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

@onready
var target_pos : Vector2 = position;

var sleep : float = 0
var blink_effect_duration : float = 0
var blink_duration : int = 2
var blink : int = 0
func _process(delta : float):
	if blink_effect_duration > 0:
		sleep += delta
		blink_effect_duration -= delta
		if sleep >= App.FPS_DOT:
			sleep = 0
			blink += 1
			if blink >= blink_duration:
				actor_sprite.visible = !actor_sprite.visible
				blink = 0
	else:
		actor_sprite.visible = true
	position = position.lerp(target_pos, 5.0 * delta)
	if Input.is_action_just_released("ui_accept"):
		blink_effect_duration += 1.0;
	if Input.is_action_just_pressed("ui_left"):
		target_pos.x -= App.TILE_SIZE
