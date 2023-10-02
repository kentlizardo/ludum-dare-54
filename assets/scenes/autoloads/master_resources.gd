extends Node

const TILES_MASTER = preload("res://assets/textures/master_tiles.png")
const ACTOR_MASTER = preload("res://assets/textures/actors/actors.png")

func create_atlas_from_master(region : Rect2, master : Texture2D) -> AtlasTexture:
	var tex = AtlasTexture.new()
	tex.atlas = master
	tex.region = region
	return tex

var unique_tile_sprites : Dictionary = {}
var unique_column_sprites : Dictionary = {}
var unique_decal_sprites : Dictionary = {}
var unique_actor_sprites : Dictionary = {}

func get_tile_sprite(key : Vector2i) -> Texture2D:
	if key.y == -1: # if variant is not set
		return access_source(key, unique_tile_sprites,
			create_atlas_from_master.bind(Rect2(16 * key.x, 0, 16, 16), TILES_MASTER))
	else:
		return access_source(key, unique_tile_sprites,
			create_atlas_from_master.bind(Rect2(16 * key.x, 64 + key.y * 16, 16, 16), TILES_MASTER))
func get_column_sprite(key : int) -> Texture2D:
	return access_source(key, unique_column_sprites,
	create_atlas_from_master.bind(Rect2(16 * key, 16, 16, 48), TILES_MASTER))
func get_decal_sprite(key : Vector2i) -> Texture2D:
	return access_source(key, unique_column_sprites,
	create_atlas_from_master.bind(Rect2(16 * key.x, 256 - key.y - 16, 16, 16), TILES_MASTER)
	)
func get_actor_sprite(key: int) -> Texture2D:
	var x : int = key % 8
	var y : int = key / 8
	return access_source(key, unique_actor_sprites,
	create_atlas_from_master.bind(Rect2(x * 16, y * 16, 16, 16), ACTOR_MASTER))

func access_source(key : Variant, source : Dictionary, fallback : Callable):
	if source.has(key):
		return source[key]
	var val = fallback.call()
	unique_decal_sprites[key] = val
	return val
