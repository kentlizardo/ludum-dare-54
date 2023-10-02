extends RefCounted
class_name ChunkData

enum CHUNK_TERRAIN {
	SAND=1,
	SLATE=2,
	HEX=3
}

var seed : int = 0
var pos : Vector2i = Vector2i.ZERO
var terrain : CHUNK_TERRAIN = CHUNK_TERRAIN.SAND
var terrain_variant : int = -1;
var height : int = 0
var hexed : bool = false
var cracking : int = 0 # 0 to 3, if hexed, wont crack
var dummy_props : Dictionary:
	get:
		var decal_id = -Vector2i.ONE
		if cracking > 0:
			decal_id = Vector2(0, cracking - 1)
		if hexed:
			decal_id = Vector2(3, 0)
		return {
			"pos": pos,
			"height": height,
			"terrain_id": terrain,
			"terrain_variant": terrain_variant,
			"decal_id": decal_id,
		}
