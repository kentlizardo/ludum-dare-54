extends Node2D

enum TERRAIN {
	WHITE,
	BLACK,
	CURSE
}

const SAND_TILE = preload("res://assets/scenes/game/tiles/sand.tscn")
const SLATE_TILE = preload("res://assets/scenes/game/tiles/slate.tscn")
const PLAYER_TILE = preload("res://assets/scenes/game/actors/king_world.tscn")
const BOARD_SCENE = preload("res://assets/scenes/game/levels/board_level.tscn")

@onready
var tiles : Node2D = get_node("Tiles")

var player : Actor

class LevelData extends RefCounted:
	var chunks : Dictionary = {}
	var encounters : Dictionary = {}
	var player_pos : Vector2i = Vector2i(-4, -4)
	var count_down : int = -1

class ChunkData extends RefCounted:
	var seed : int = 0
	var pos : Vector2i = Vector2i.ZERO
	var terrain : TERRAIN = TERRAIN.WHITE

var level_data : LevelData:
	get:
		return App.data["levels"]

func _ready():
	if !App.data.has("levels"):
		randomize()
		App.data["levels"] = generate(randi())
	populate(App.data["levels"])
	var travel = func(selection):
		var tile : Tile = selection[0]
		level_data.player_pos = tile.tile_pos
		print_debug(level_data.player_pos)
		var tw = player.create_tween()
		tw.tween_property(player, "position", tile.position, 1.0)
		await tw.finished
		App.load_level(BOARD_SCENE)

	var neighboring_tiles = func(tile : Tile) -> bool:
		return Util.chebyshev_dist(tile.tile_pos, level_data.player_pos) <= App.data["move_speed"] and App.data["levels"].player_pos != tile.tile_pos
	App.start_selection(App.SELECTION_TYPES.TILE,  # flags
		travel, # confirm
		Util.EMPTY_CALLABLE, # cancel
		func(arr : Array) -> bool: return arr.size() == 1, # selection validate
		neighboring_tiles, # choice
		)

const WIDTH = 8;
const HEIGHT = 8;
func generate(seed : int) -> LevelData:
	var level_data = LevelData.new()
	var gen = RandomNumberGenerator.new()
	gen.seed = seed
	for i in range(8):
		for j in range(8):
			var grid_pos = Vector2i(i - 4, j - 4)
			var hash = j * (8 << 1) + i # Might be useful later
			var chunk = ChunkData.new()
			chunk.seed = gen.randi()
			if (i + j) % 2 == 0:
				chunk.terrain = TERRAIN.WHITE
			else:
				chunk.terrain = TERRAIN.BLACK
			level_data.chunks[grid_pos] = chunk
	return level_data

func populate(data : LevelData):
	for chunk_pos in data.chunks.keys():
		var chunk = data.chunks[chunk_pos]
		var tile : Tile = null
		match chunk.terrain:
			TERRAIN.WHITE:
				tile = SAND_TILE.instantiate()
			TERRAIN.BLACK:
				tile = SLATE_TILE.instantiate()
		if tile != null:
			tile.position = Tile.CENTER_OFFSET + chunk_pos * App.TILE_SIZE
			self.tiles.add_child(tile)
	for i in range(5):
		var tile : Tile
		if i % 2 == 0:
			tile = SAND_TILE.instantiate()
		else:
			tile = SLATE_TILE.instantiate()
		if tile != null:
			tile.position = Tile.CENTER_OFFSET + Vector2i(-6, -4 + i) * App.TILE_SIZE
			self.tiles.add_child(tile)
	for chunk_pos in data.encounters.keys():
		var encounter = data.encounters[chunk_pos]
	player = PLAYER_TILE.instantiate()
	player.position = data.player_pos * App.TILE_SIZE + Tile.CENTER_OFFSET
	self.add_child(player)
	
