extends Node2D

enum ENCOUNTER_TYPE { 
	BASIC,
	COMBAT,
}

enum CHUNK_TERRAIN {
	SAND,
	SLATE,
	HEX
}


const BOARD_LEVEL = preload("res://assets/scenes/game/levels/_board_level.tscn")

@onready
var tiles_root : Node2D = get_node("Tiles")
@onready
var actors_root : Node2D = get_node("Actors")

var links : Dictionary = {} # ChunkData/EncounterData/ActorTemplateData -> Tile/Actor

func flash(lvl_data : LevelData):
	print_debug("Flashing Level_Select")
	# Create Links
	for chunk in lvl_data.chunks:
		if !links.has(chunk):
			var tile : Tile = App.TILE_TEMPLATE.instantiate()
			tiles_root.add_child(tile)
			links[chunk] = tile
			tile.flash(TileEntity.create_dummy(chunk.dummy_props), true)
	for encounter in lvl_data.encounters:
		if !links.has(encounter):
			var actor : Actor = App.ACTOR_TEMPLATE.instantiate()
			actors_root.add_child(actor)
			links[encounter] = actor
			actor.flash(ActorEntity.create_dummy(encounter.dummy_props), true)
	for member in lvl_data.team:
		if !links.has(member):
			var actor : Actor = App.ACTOR_TEMPLATE.instantiate()
			actors_root.add_child(actor)
			links[member] = actor
			var d_p : Dictionary = member.dummy_props
			var member_index : int = lvl_data.team.find(member)
			if member_index != 0:
				d_p["pos"] = Vector2i(-6, -4 + member_index - 1)
			else:
				d_p["pos"] = member.pos
			actor.flash(ActorEntity.create_dummy(d_p), true)
	# Remove links that aren't in level_data
	for key in links.keys():
		if key is EncounterData:
			if !lvl_data.encounters.has(key):
				var link : Actor = links[key]
				link.destroy()
				links.erase(key)
		if key is ChunkData:
			if !lvl_data.chunks.has(key):
				var link : Tile = links[key]
				link.destroy()
				links.erase(key)
		if key is ActorTemplateData:
			if !lvl_data.team.has(key):
				var link : Actor = links[key]
				link.destroy()
				links.erase(key)
	# Change existing links
	for chunk in lvl_data.chunks:
		if links.has(chunk):
			var link : Tile = links[chunk]
			link.flash(TileEntity.create_dummy(chunk.dummy_props), false)
	for encounter in lvl_data.encounters:
		if links.has(encounter):
			var link : Actor = links[encounter]
			link.flash(ActorEntity.create_dummy(encounter.dummy_props), false)
	for member in lvl_data.team:
		if links.has(member):
			var link : Actor = links[member]
			var d_p : Dictionary = member.dummy_props
			var member_index : int = lvl_data.team.find(member)
			if member_index != 0:
				d_p["pos"] = Vector2i(-6, -4 + member_index - 1)
			else:
				d_p["pos"] = member.pos
			link.flash(ActorEntity.create_dummy(d_p), false)
	# Remove nodes that aren't linked
	for actor in Util.get_children_recursive(actors_root):
		if actor is Actor:
			if !links.values().has(actor):
				actor.destroy()
	for tile in Util.get_children_recursive(tiles_root):
		if tile is Tile:
			if !links.values().has(tile):
				tile.destroy()

const PLAYER_ACTOR : ActorEntity = preload("res://assets/resources/entities/actors/king.tres")

class LevelData extends RefCounted:
	var chunks : Array[ChunkData] = []
	var encounters : Array[EncounterData] = []
	var team : Array[ActorTemplateData] = [
		ActorTemplateData.from_actor(PLAYER_ACTOR),
	]
	var player_pos : Vector2i:
		get:
			return team[0].pos
		set(x):
			team[0].pos = x
	var count_down : int = -1
	func _init():
		team[0].pos = Vector2i(-4, -4)

class ActorTemplateData extends RefCounted:
	var pos : Vector2i = Vector2i.ZERO
	var real_actor : ActorEntity = null
	var dummy_props : Dictionary:
		get:
			if real_actor:
				var dict = Util.create_simple_property_dict(real_actor)
				return dict
			else: return {}
	static func from_actor(b : ActorEntity) -> ActorTemplateData:
		var template = ActorTemplateData.new()
		template.real_actor = b.duplicate()
		return template

class ChunkData extends RefCounted:
	var seed : int = 0
	var pos : Vector2i = Vector2i.ZERO
	var terrain : CHUNK_TERRAIN = CHUNK_TERRAIN.SAND
	var dummy_props : Dictionary:
		get:
			return {
				"pos": pos
			}

class EncounterData extends RefCounted:
	var type : ENCOUNTER_TYPE = ENCOUNTER_TYPE.BASIC
	var on_meet : Callable = Util.EMPTY_CALLABLE
	var pos : Vector2i = Vector2i.ZERO
	var dummy_props : Dictionary:
		get:
			return {
				"pos": pos,
				
			}
	func _init(type : ENCOUNTER_TYPE, on_meet : Callable):
		self.type = type
		self.on_meet = on_meet
	func meet():
		on_meet.call()
		match type:
			ENCOUNTER_TYPE.BASIC:
				pass
			ENCOUNTER_TYPE.COMBAT:
				App.load_level(BOARD_LEVEL)

var level_data : LevelData:
	get:
		return App.data["levels"]

func create_travel_event() -> App.Event:
	return App.Event.new(
		Util.EMPTY_CALLABLE,
		start_turn.bind(),
		Util.EMPTY_CALLABLE,
	)

var travel_call = func(selection):
	App.hint = ""
	var tile : Tile = selection[0]
	for chunk in level_data.chunks.duplicate():
		if chunk.pos == level_data.player_pos:
			level_data.chunks.remove_at(level_data.chunks.find(chunk))
	level_data.player_pos = tile.tile_pos
	await flash(level_data)
	var occluding_encounters = level_data.encounters.filter(func(x): return x.pos == level_data.player_pos)
	if occluding_encounters.size() > 0:
		var encounter = occluding_encounters[0]
		encounter.meet()
	else:
		App.push_event(create_travel_event())
func start_turn():
	print_debug("Starting new turn")
	var neighboring_tiles = func(tile : Tile) -> bool:
		print_debug("Neighboring")
		return Util.chebyshev_dist(tile.tile_pos, App.data["levels"].player_pos) <= App.data["move_speed"] and App.data["levels"].team[0].pos != tile.tile_pos
	App.hint = "select a tile to move to"
	App.start_selection(App.SELECTION_TYPES.TILE,  # flags
		travel_call, # confirm
		Util.EMPTY_CALLABLE, # cancel
		func(arr : Array) -> bool: return arr.size() == 1, # selection validate
		neighboring_tiles if OS.is_debug_build() else Util.EMPTY_CALLABLE, # choice
		)

func _ready():
	if !App.data.has("levels"):
		randomize()
		App.data["levels"] = generate(randi())
	await flash(level_data)
	App.push_event(create_travel_event())

const WIDTH = 8;
const HEIGHT = 8;
func generate(seed : int) -> LevelData:
	var data = LevelData.new()
	var gen = RandomNumberGenerator.new()
	gen.seed = seed
	var unoccupied : Array = []
	for i in range(8):
		for j in range(8):
			var grid_pos = Vector2i(i - 4, j - 4)
			unoccupied.append(grid_pos)
			var hash = j * (8 << 1) + i # Might be useful later
			var chunk = ChunkData.new()
			chunk.seed = gen.randi()
			chunk.pos = grid_pos
			if (i + j) % 2 == 0:
				chunk.terrain = CHUNK_TERRAIN.SAND
			else:
				chunk.terrain = CHUNK_TERRAIN.SLATE
			data.chunks.append(chunk)
	for x in range(gen.randi_range(6, 8)): # enemy spawns
		var pos = unoccupied.pick_random()
		if pos:
			unoccupied.remove_at(unoccupied.find(pos))
			var encounter = EncounterData.new(ENCOUNTER_TYPE.COMBAT, create_combat_encounter(gen.randi(), pos))
			encounter.pos = pos
			data.encounters.append(encounter)
	return data

func create_board_generator(chunk: ChunkData, enc : EncounterData) -> Callable:
	var board_gen : Callable = func(board : Board):
		var unoccupied : Array[Vector2i] = []
		for i in range(8):
			for j in range(8):
				var grid_pos = Vector2i(i - 4, j - 4)
				unoccupied.append(grid_pos)
				var t_ent = TileEntity.new(board)
	return board_gen
#				if (i + j) % 2 == 0:
#					t_ent.tex = 
#				else:
#					chunk.terrain = TERRAIN.BLACK

func create_combat_encounter(seed : int, chunk_pos : Vector2i) -> Callable:
	var meet : Callable = func():
		App.data["board"] = create_board_generator.call(seed, chunk_pos)
	return meet
