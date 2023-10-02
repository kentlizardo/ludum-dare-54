extends Node
class_name Board

signal win
signal lose

var entities : Array[BoardEntity] = []

func get_tile_at(pos : Vector2i) -> TileEntity:
	for tile in get_tile_map().values():
		if pos == tile.pos:
			return tile
	return null
func get_tiles_at(positions : Array) -> Array:
	var arr : Array[TileEntity] = []
	for tile in get_tile_map().values():
		if positions.has(tile.pos):
			arr.append(tile)
	return arr

func is_unoccupied(pos : Vector2i) -> bool:
	var tile = get_tile_at(pos)
	if tile == null:
		return false
	return get_actor_at(pos) == null

func get_actor_at(pos : Vector2i) -> ActorEntity:
	for actor in get_actors_map().values():
		if pos == actor.pos:
			return actor
	return null

func get_tile_map() -> Dictionary: # Vector2i -> TileEntity
	var map = {}
	for ent in entities:
		if ent is TileEntity:
			map[ent.pos] = ent
	return map
func get_actors_map() -> Dictionary: # Vector2i -> ActorEntity
	var map = {}
	for ent in entities:
		if ent is ActorEntity:
			map[ent.pos] = ent
	return map

static var board : Board = null
func _ready():
	board = self
	App.data["levels"] = LevelData.new()
	create_board(self)
#	App.data["board"].call(self)
	App.push_event(setup_board_event)

const TERRAIN_TILES = {
	ChunkData.CHUNK_TERRAIN.SLATE: [0,1],
	ChunkData.CHUNK_TERRAIN.SAND: [0,1],
	ChunkData.CHUNK_TERRAIN.HEX: [0,1,2,3],
}
func create_board(board : Board): # shortended jam version
	var entities : Array[BoardEntity] = []
	randomize()
	var gen = RandomNumberGenerator.new()
	gen.seed = randi()
	
	var height_map : Dictionary = {} # Vector2i to int(tile height)
	for i in range(8):
		for j in range(8):
			var grid_pos = Vector2i(i - 4, j - 4)
			height_map[grid_pos] = 0
	
	var dissolve_tiles : int = 0
	for i in range(2):
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
		tile.terrain_id = [ChunkData.CHUNK_TERRAIN.SLATE, ChunkData.CHUNK_TERRAIN.SAND, ChunkData.CHUNK_TERRAIN.SLATE, ChunkData.CHUNK_TERRAIN.SAND, ChunkData.CHUNK_TERRAIN.SLATE, ChunkData.CHUNK_TERRAIN.SAND, ChunkData.CHUNK_TERRAIN.HEX].pick_random()
		tile.terrain_variant = TERRAIN_TILES[tile.terrain_id].pick_random() - 1
		tile.height = height_map[key]
	
	var unoccupied : Array = height_map.keys()
	var dir = DirAccess.open("res://assets/resources/entities/actors/enemies/")
	var enemy_list = []
	for enemy_res in dir.get_files():
		enemy_list.append(load("res://assets/resources/entities/actors/enemies/" + enemy_res) as ActorEntity)
	for i in range(0, 5):
		var pos = unoccupied.pick_random()
		unoccupied.remove_at(unoccupied.find(pos))
		var token = enemy_list.pick_random().duplicate()
		token.board = board
		token.move_left = token.move_speed
		token.pos = pos

func _process(delta):
	if App.game_state == App.GAME_STATE.IDLE:
		if App.data["levels"].team[0].token_actor == null:
			App.data["levels"] = LevelData.new()
			App.push_event(EventTemplateSwitchScene.event_template(load("res://assets/scenes/game/levels/revive.tscn")))
			return
		App.push_event(player_turn_event())

func move_actor_to_pos(actor: ActorEntity, pos : Vector2i):
	if is_unoccupied(pos):
		if actor.horse_movement:
			actor.move_left = 0
		else:
			actor.move_left -= 1
		actor.pos = pos
	else:
		var enemy : ActorEntity = get_actor_at(pos)
		enemy.health -= actor.attack
		enemy.helpers.append("damaged")
		if enemy.health <= 0:
			enemy.board = null
			if App.data["levels"].team.values().has(enemy):
				App.data["levels"].team.filter(func(x:ActorTemplateData): return x.token_actor == enemy).all(func(x):x.token_actor = null)
		actor.attacked = true

func player_turn_event() -> App.Event:
	return App.Event.new(
	Util.EMPTY_CALLABLE,
	func():
		var level_data : LevelData = App.data["levels"]
		level_data.team.all(func(x : ActorTemplateData):
			if x.token_actor != null:
				x.token_actor.attacked = false
				x.token_actor.move_left = x.token_actor.move_speed
			)
		var turn : Dictionary = {
			"ended": false,
		}
		var end_call = func():
			App.reset_selection()
			turn.ended = true
			App.end_btn.visible = false
		App.end_btn.visible = true
		App.end_btn.pressed.connect(end_call)
		while !turn.ended and level_data.team.any(func(x : ActorTemplateData): 
				if x.token_actor != null:
					if !x.token_actor.tired:
						return true
				return false
				):
			var action = {}
			var actors_left = []
			for i in App.board_view.links.keys():
				if i is ActorEntity:
					if i.controlled == ActorEntity.CONTROL.PLAYER and !i.tired:
						actors_left.append(App.board_view.links[i])
			await App.start_selection_from(
				actors_left,
				App.SELECTION_TYPES.ACTOR,
				true,
				func(confirmed_selection): # confirm
					action.actor = confirmed_selection[0]
					,
				func(): # cancel
					pass,
				func(selection): # validate
					return selection.size() == 1,
			)
			if !action.has("actor"):
				continue
			var actor_source : ActorEntity = App.board_view.reverse_actor(action.actor)
			var possible_tiles = get_tiles_at(actor_source.get_move_tiles()).map(func(x : TileEntity): return App.board_view.links[x])
			await App.start_selection_from(
				possible_tiles,
				App.SELECTION_TYPES.TILE,
				true,
				func(confirmed_selection): # confirm
					action.tile = confirmed_selection[0]
					,
				func(): # cancel
					pass,
				func(selection): # validate
					return selection.size() == 1,
			)
			if !action.has("tile"):
				continue
			var tile_source : TileEntity = App.board_view.reverse_tile(action.tile)
			if is_unoccupied(tile_source.pos):
				if actor_source.move_left > 0:
					move_actor_to_pos(actor_source, tile_source.pos)
				else:
					App.hint = "cannot move any more"
			else:
				if !actor_source.attacked:
					move_actor_to_pos(actor_source, tile_source.pos)
				else:
					App.hint = "can only attack once"
			await App.board_view.flash(self)
		await App.board_view.flash(self)
		App.end_btn.visible = false
		entities.all(func(x:BoardEntity):
			if x is ActorEntity:
				if x.controlled == ActorEntity.CONTROL.ENEMY:
					x.move_left = x.move_speed
					x.attacked = false
		)
		var remaining_entities : Array = []
		remaining_entities = entities.filter(func(x:BoardEntity):
			if x is ActorEntity:
				if x.controlled == ActorEntity.CONTROL.ENEMY and !x.tired:
					return true
			return false
		)
		while remaining_entities.size() > 0:
			var enemy_entity : ActorEntity = remaining_entities.pick_random()
			var closest_enemy : ActorEntity = null
			var enemies : Array = entities.filter(func(x:BoardEntity): if x is ActorEntity:
				return x.controlled != enemy_entity.controlled
				)
			if enemies.size() == 0:
				break
			var dist : float = -1.0
			for enemy in enemies:
				if dist < 0: # first value
					dist = (enemy.pos - enemy_entity.pos).length()
					closest_enemy = enemy
				else:
					var new_dist = (enemy.pos - enemy_entity.pos).length()
					if new_dist < dist:
						dist = new_dist
						closest_enemy = enemy
			
			var priorities : Dictionary = {}
			var options = get_tiles_at(enemy_entity.get_move_tiles())
			for i in options:
				priorities[i] = 1
			for tile in options:
				if is_unoccupied(tile.pos):
					priorities[tile] = 2 + 1 if (tile.pos - closest_enemy.pos).length() < dist else 0
				else:
					if get_actor_at(tile.pos).controlled != enemy_entity.controlled:
						priorities[tile] = 5
					else:
						priorities[tile] = 0
			var grab_bag = []
			for i in priorities.keys():
				for j in range(priorities[i]):
					grab_bag.append(i)
			if grab_bag.size() > 0:
				var rand = grab_bag.pick_random()
				move_actor_to_pos(enemy_entity, rand.pos)
			else:
				enemy_entity.attacked = true
				enemy_entity.move_left = 0
			await App.board_view.flash(self)
			remaining_entities = entities.filter(func(x:BoardEntity):
				if x is ActorEntity:
					if x.controlled == ActorEntity.CONTROL.ENEMY and !x.tired:
						return true
				return false
			)
		await App.board_view.flash(self)
		,
	Util.EMPTY_CALLABLE,
	)

#func player_turn_event() -> App.Event:
#	return App.Event.new(
#		Util.EMPTY_CALLABLE,
#		func():
#			for actor in entities:
#				if actor is ActorEntity:
#					actor.tired = false
#			await App.board_view.flash(self)
#			Turn.start_turn()
#			while Turn._turn.ongoing:
#				match Turn._turn.state:
#					Turn.TURN_STATE.INSPECTING:
#						if !App.selecting:
#							App.start_selection(
#								App.SELECTION_TYPES.ACTOR,
#								true,
#								func(confirmed_selection):
#									var act : Actor = confirmed_selection[0]
#									if App.player_inspect == act:
#										App.player_inspect = null
#										return
#									if App.npc_inspect == act:
#										App.npc_inspect = null
#										return
#									if act.controlled:
#										App.player_inspect = act
#									else:
#										App.npc_inspect = act,
#								Util.EMPTY_CALLABLE,
#								func(sel : Array[Variant]):
#									return sel.size() == 1 and sel[0].inspectable,
#								func(act : Actor):
#									return act.inspectable,
#							)
#				await get_tree().process_frame
#			await App.board_view.flash(self),
#		Util.EMPTY_CALLABLE,
#	)

func register_entity(e : BoardEntity):
	entities.append(e)

func unregister_entity(e : BoardEntity):
	entities.remove_at(entities.find(e))

var setup_board_event = App.Event.new(
	Util.EMPTY_CALLABLE,
	func():
		var level_data : LevelData = App.data["levels"]
		level_data.team.all(func(x : ActorTemplateData): x.token_actor = null)
		await App.board_view.flash(self)
		var props = {"val": 0,
			"deploy_satisfied": level_data.team[0].token_actor != null,
			"deployed": false
		}
		var deploy_call = func():
			props.deploy_satisfied = level_data.team[0].token_actor != null
			if props.deploy_satisfied:
				App.reset_selection()
				props.deployed = true
				App.end_btn.visible = false
			else:
				props.val += 1
				if props.val < 5:
					App.hint = "your king must be deployed before battle."
				else:
					App.speak_dialog("only a king who is a coward will not fight with his troops.", null, null)
		App.end_btn.visible = true
		App.end_btn.pressed.connect(deploy_call)
		while !props.deployed:
			App.hint = "select a unit to deploy."
			var deploy_actors = App.board_view.deploy_links.values()
			for member in level_data.team:
				if member.token_actor != null:
					deploy_actors.append(App.board_view.links[member.token_actor])
			var deployment : Dictionary = {
				"actor": null,
				"tile": null,
			}
			await App.start_selection_from(
				deploy_actors,
				App.SELECTION_TYPES.ACTOR,
				true,
				func(confirmed_selection): # confirm
					deployment.actor = confirmed_selection[0]
					,
				func(): # cancel
					pass,
				func(selection): # validate
					return selection.size() == 1,
			)
			if deployment.actor == null:
				continue
			var possible_tile_nodes : Array[Node] = Util.get_children_recursive(App.board_view.tiles_root)
			possible_tile_nodes.append_array(Util.get_children_recursive(App.board_view.temp_tiles_root))
			var all_tiles = possible_tile_nodes.filter(func(x): return x is Tile)
			App.hint = "select a tile."
			await App.start_selection_from(
				all_tiles,
				App.SELECTION_TYPES.TILE,
				true,
				func(confirmed_selection): # confirm
					deployment.tile = confirmed_selection[0]
					,
				func(): # cancel
					pass,
				func(selection): # validate
					return selection.size() == 1,
			)
			if deployment.tile == null:
				continue
			App.hint = ""
			if deployment.tile != null and deployment.actor != null:
				var actor_source : Variant = App.board_view.reverse_actor(deployment.actor)
				var tile_source : Variant = App.board_view.reverse_tile(deployment.tile)
				if actor_source is ActorTemplateData: # yet to be deployed
					if tile_source is ActorTemplateData: # invalid, moving deployed to deployed
						continue
					elif tile_source is TileEntity: # deployed to tangible tile
						var token : ActorEntity = actor_source.real_actor.duplicate()
						token.pos = tile_source.pos
						actor_source.token_actor = token
						token.board = self
						tile_source.pos
				elif actor_source is ActorEntity: # selecting an already deployed_actor
					if tile_source is ActorTemplateData: # undeploying
						tile_source.token_actor.board = null
						tile_source.token_actor = null
					elif tile_source is TileEntity: # switching locations
						actor_source.pos = tile_source.pos
				await App.board_view.flash(self)
		App.hint = ""
		await App.board_view.flash(self)
		,
	Util.EMPTY_CALLABLE,
	)

