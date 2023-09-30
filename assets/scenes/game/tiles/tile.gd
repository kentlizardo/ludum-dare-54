extends Node2D

class_name Tile

@onready
var og_pos : Vector2 = self.position;

@export
var tile_sprite : Sprite2D
@onready
var tile_sprite_bind : SpriteBind = SpriteBind.new(tile_sprite)

@export
var tile_under_sprite : Sprite2D
@onready
var tile_under_sprite_bind : SpriteBind = SpriteBind.new(tile_under_sprite)

const SHAKE_VEC = Vector2(1, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#var accel : float = 0;
#var sleep : float = 0;
### Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	sleep += delta
#	if sleep >= App.FPS_DOT:
#		sleep = 0;
#		tile_sprite.position = tile_sprite_rel_pos + SHAKE_VEC * randi_range(-1, 1)
#		tile_under_sprite.position = tile_under_sprite_rel_pos + SHAKE_VEC * randi_range(-1, 1)
#		accel += 0.1;
#		position.y += accel;
#func _input(event):
#	if Input.is_action_pressed("ui_accept"):
#		position = og_pos; 
#		accel = 0;
