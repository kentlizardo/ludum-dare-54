extends Node2D

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


var level_data : LevelData:
	get:
		return App.data["levels"]

func create_travel_event() -> App.Event:
	return App.Event.new(
		Util.EMPTY_CALLABLE,
		start_turn.bind(),
		Util.EMPTY_CALLABLE,
	)

# optimize later
func crack_map(rows : int, cols : int) -> Vector2i:
	var bag = []
	for i in range(rows):
		for j in range(cols):
			var weight = abs(i - j)
			for k in range(weight):
				bag.push_back(Vector2i(i, j))
	return bag.pick_random()
func corrupt_map(rows : int, cols : int) -> Vector2i:
	var bag = []
	for i in range(rows):
		for j in range(cols):
			var weight = abs(i + j)
			for k in range(weight):
				bag.push_back(Vector2i(i, j))
	return bag.pick_random()

var travel_call = func(selection):
	App.hint = ""
	var tile : Tile = selection[0]
	for chunk in level_data.chunks.duplicate():
		if chunk.pos == level_data.player_pos:
			level_data.chunks.remove_at(level_data.chunks.find(chunk))
	level_data.player_pos = tile.tile_pos
	level_data.count_down += 1
	if level_data.count_down % 4 == 0:
		level_data.chunks.remove_at(level_data.chunks.find(level_data.chunks.duplicate().pick_random()))
	if level_data.count_down % 3 == 0:
		var random_crack = corrupt_map(8, 8)
		while !level_data.chunks.any(func(chunk : ChunkData): return chunk.pos == random_crack):
			random_crack = corrupt_map(8, 8)
		var chunk = level_data.chunks.filter(func(chunk : ChunkData): return chunk.pos == random_crack)[0]
		if chunk.hexed:
			chunk.hexed = false
			if chunk.terrain == ChunkData.CHUNK_TERRAIN.HEX:
				pass
			else:
				chunk.terrain = ChunkData.CHUNK_TERRAIN.HEX
		else:
			if chunk.terrain == ChunkData.CHUNK_TERRAIN.HEX:
				chunk.hexed = true
			else:
				chunk.terrain = ChunkData.CHUNK_TERRAIN.HEX
	if level_data.count_down % 2 == 0:
		var random_crack = crack_map(8, 8)
		while !level_data.chunks.any(func(chunk : ChunkData): return chunk.pos == random_crack):
			random_crack = crack_map(8, 8)
		var chunk = level_data.chunks.filter(func(chunk : ChunkData): return chunk.pos == random_crack)[0]
		chunk.cracking += 1
		if chunk.cracking > 3:
			level_data.chunks.remove_at(level_data.chunks.find(level_data.chunks.duplicate().pick_random()))
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
		return Util.chebyshev_dist(tile.tile_pos, level_data.player_pos) <= level_data.team[0].real_actor.move_speed and level_data.player_pos != tile.tile_pos
	App.hint = "select a tile to move to"
	App.start_selection(App.SELECTION_TYPES.TILE,  # flags
		true, # autoconfirm
		travel_call, # confirm
		Util.EMPTY_CALLABLE, # cancel
		func(arr : Array) -> bool: return arr.size() == 1, # selection validate
		neighboring_tiles if !OS.is_debug_build() else Util.EMPTY_CALLABLE, # choice
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
				chunk.terrain = ChunkData.CHUNK_TERRAIN.SAND
			else:
				chunk.terrain = ChunkData.CHUNK_TERRAIN.SLATE
			data.chunks.append(chunk)
	for x in range(gen.randi_range(14, 16)): # enemy spawns
		var pos = unoccupied.pick_random()
		if pos:
			unoccupied.remove_at(unoccupied.find(pos))
			var encounter = EncounterData.new(EncounterData.ENCOUNTER_TYPE.COMBAT, create_combat_encounter)
			encounter.pos = pos
			data.encounters.append(encounter)
	var random_encounters = [
#		func():
#			App.push_event(EventTemplateDialog.event_template("You travel for a while on foot, until your treads meet raw scavenger.", null, null))
#			push_event(EventTemplateDialog.event_template("You travel for a while on foot, until your treads meet raw scavenger.", null, null)),
#		func():
#			App.push_event(EventTemplateDialog.event_template()),
#		func():
#			App.push_event(EventTemplateDialog.event_template()),
#		func():
#			App.push_event(EventTemplateDialog.event_template()),
	]
#	for x in range(gen.randi_range(14, 16)): # enemy spawns
#		var pos = unoccupied.pick_random()
#		if pos:
#			unoccupied.remove_at(unoccupied.find(pos))
#			var enc = random_encounters.find(random_encounters.pick_random())
#			var encounter = EncounterData.new(EncounterData.ENCOUNTER_TYPE.BASIC, )
#			encounter.pos = pos
#			data.encounters.append(encounter)
	return data

const TERRAIN_TILES = {
	ChunkData.CHUNK_TERRAIN.SLATE: [0,1],
	ChunkData.CHUNK_TERRAIN.SAND: [0,1],
	ChunkData.CHUNK_TERRAIN.HEX: [0,1,2,3],
}
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
	for i in range(chunk.cracking + 1):
		dissolve_tiles += gen.randi() % 6
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
	
	for key in height_map.keys():
		var tile = TileEntity.new(board)
		tile.pos = key
		tile.height = height_map[key]
		tile.terrain_id = chunk.terrain
		tile.terrain_variant = TERRAIN_TILES[tile.terrain_id].pick_random()
		tile.height = height_map[key]
	
	var unoccupied : Array = height_map.keys()
	var x : ActorEntity = load("res://assets/resources/entities/actors/sentinel.tres")
	for i in range(0, 5):
		var pos = unoccupied.pick_random()
		unoccupied.remove_at(unoccupied.find(pos))
		var token = x.duplicate()
		token.board = board
		token.pos = pos

#	var unoccupied : Array[Vector2i] = []
#		unoccupied.append(grid_pos)

func create_combat_encounter(enc : EncounterData):
	App.data["board"] = create_board.bind(enc)
