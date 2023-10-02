extends Node2D

enum ENCOUNTER_TYPE { 
	BASIC,
	COMBAT,
	SPECIAL,
}

enum CHUNK_TERRAIN {
	SAND=1,
	SLATE=2,
	HEX=3
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
	while Tile.flashing_tiles.size() > 0 and Actor.flashing_actors.size() > 0:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout

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
		if on_meet != Util.EMPTY_CALLABLE:
			on_meet.call(self)
		match type:
			ENCOUNTER_TYPE.BASIC:
				pass # add node, await until node is complete/readied.
			ENCOUNTER_TYPE.SPECIAL:
				pass # load level?
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
	for x in range(gen.randi_range(14, 16)): # enemy spawns
		var pos = unoccupied.pick_random()
		if pos:
			unoccupied.remove_at(unoccupied.find(pos))
			var encounter = EncounterData.new(ENCOUNTER_TYPE.COMBAT, create_combat_encounter)
			encounter.pos = pos
			data.encounters.append(encounter)
	return data

func create_board(board : Board, enc : EncounterData): # argument list must be this way for chaining binds
	assert(enc != null)
	var entities : Array[BoardEntity] = []
	var chunk : ChunkData
	for c in level_data.chunks:
		if c.pos == enc.pos:
			chunk = c
	var gen = RandomNumberGenerator.new()
	gen.seed = chunk.seed
	
	var height_map : Dictionary = {} # Vector2i to int(tile height)
	for i in range(8):
		for j in range(8):
			var grid_pos = Vector2i(i - 4, j - 4)
			height_map[grid_pos] = 0
	
	var dissolve_tiles : int = 0
	for i in range(chunk.cracking):
		dissolve_tiles += gen.randi() % 6
		dissolve_tiles += gen.randi() % 6
	
	var weighted_dissolve : Array[Vector2i] = []
	for key in height_map.keys():
		var pos : Vector2i = key
		for i in range(pos.length() + 2):
			weighted_dissolve.append(pos)
	
	for i in range(dissolve_tiles):
		var dissolve_pos = weighted_dissolve.pick_random()
		if height_map.keys().has(dissolve_pos):
			height_map.erase(dissolve_pos)
	
	for i in height_map.values():
		var tile = TileEntity.new(board)
		tile.terrain_id = 1
		tile.height = 0

#	var unoccupied : Array[Vector2i] = []
#		unoccupied.append(grid_pos)

func create_combat_encounter(enc : EncounterData):
	App.data["board"] = create_board.bind(enc)
