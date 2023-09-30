extends RefCounted

class_name SpriteBind

var sprite : Sprite2D:
	set(x):
		sprite = x
		sprite_pos = sprite.position if sprite != null else Vector2.ZERO
	get:
		return 
var sprite_pos : Vector2

func _init(s : Sprite2D):
	sprite = s
