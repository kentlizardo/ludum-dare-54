extends Node2D

class_name BoardView

@onready
var tiles_root : Node2D = get_node("Tiles")
@onready
var actors_root : Node2D = get_node("Actors")

@onready
var temp_tiles_root : Node2D = get_node("TempTiles")
@onready
var temp_actors_root : Node2D = get_node("TempActors")

var links : Dictionary = {} # BoardEntity -> Actor/Tile

var deploy_links : Dictionary = {} # ActorTemplateData -> Actor
var deploy_tiles : Dictionary = {} # ActorTemplateData -> Tile

func find_entity(node : Node) -> BoardEntity:
	for i in links.keys():
		if links[i] == node:
			return i
	return null

func reverse_actor(actor : Actor) -> Variant:
	for i in links.keys():
		if links[i] == actor: # ActorEntity
			return i
	for i in deploy_links.keys(): # ActorTemplateData
		if deploy_links[i] == actor:
			return i
	return null

func reverse_tile(tile : Tile) -> Variant:
	for i in links.keys():
		if links[i] == tile: # Tile
			return i
	for i in deploy_tiles.keys(): # ActorTemplateData
		if deploy_tiles[i] == tile:
			return i
	return null


func flash(board : Board):
	var lvl_data : LevelData = App.data["levels"]
	print_debug("Started flashing board")
	# Create Links
	for entity in board.entities:
		if !links.has(entity):
			if entity is ActorEntity:
				var actor : Actor = App.ACTOR_TEMPLATE.instantiate()
				actors_root.add_child(actor)
				links[entity] = actor
				actor.flash(entity, true)
			if entity is TileEntity:
				var tile : Tile = App.TILE_TEMPLATE.instantiate()
				tiles_root.add_child(tile)
				links[entity] = tile
				tile.flash(entity, true)
	for member in lvl_data.team:
		var member_index : int = lvl_data.team.find(member)
		var show_on_sidebar : bool = !deploy_links.has(member) and member.token_actor == null
		if show_on_sidebar:
			var actor : Actor = App.ACTOR_TEMPLATE.instantiate()
			temp_actors_root.add_child(actor)
			deploy_links[member] = actor
			var d_p : Dictionary = member.dummy_props
			d_p["pos"] = Vector2i(-6, -4 + member_index)
			d_p["tired"] = false
			actor.flash(ActorEntity.create_dummy(d_p), true)
			# set up ground
			if !deploy_tiles.has(member):
				var tile : Tile = App.TILE_TEMPLATE.instantiate()
				temp_tiles_root.add_child(tile)
				deploy_tiles[member] = tile
				tile.flash(TileEntity.create_dummy({
					"pos": Vector2i(-6, -4 + member_index),
					"terrain_id": 1 if member_index % 2 == 0 else 2,
				}), true)
		member_index += 1
#	# Remove links that aren't in level_data
	for key in links.keys():
		if !board.entities.has(key):
			var link = links[key]
#			link.destroy() is probably unnecessary b/c of 4th step
			links.erase(key)
	for key in deploy_links.keys(): # delete every template that doesn't exist in level_data
		if !lvl_data.team.has(key) or key.token_actor != null:
			deploy_links.erase(key)
		if !lvl_data.team.has(key):
			deploy_tiles.erase(key)
	# Change existing links
	for entity in board.entities:
		if links.has(entity):
			if entity is ActorEntity:
				var actor : Actor = links[entity]
				actor.flash(entity, false)
			if entity is TileEntity:
				var tile : Tile = links[entity]
				tile.flash(entity, false)
	for member in lvl_data.team:
		var member_index : int = lvl_data.team.find(member)
		var show_on_sidebar : bool = deploy_links.has(member) and member.token_actor == null
		if show_on_sidebar:
			var actor : Actor = deploy_links[member]
			var d_p : Dictionary = member.dummy_props
			d_p["pos"] = Vector2i(-6, -4 + member_index)
			d_p["tired"] = false
			actor.flash(ActorEntity.create_dummy(d_p), false)
			# ground
			var tile : Tile = deploy_tiles[member]
			tile.flash(TileEntity.create_dummy({
				"pos": Vector2i(-6, -4 + member_index),
				"terrain_id": 1 if member_index % 2 == 0 else 2,
			}), false)
#	# Remove nodes that aren't linked
	for actor in Util.get_children_recursive(actors_root):
		if actor is Actor:
			if !links.values().has(actor):
				actor.destroy()
	for actor in Util.get_children_recursive(temp_actors_root):
		if actor is Actor:
			if !deploy_links.values().has(actor):
				actor.destroy()
	for tile in Util.get_children_recursive(tiles_root):
		if tile is Tile:
			if !links.values().has(tile):
				tile.destroy()
	for tile in Util.get_children_recursive(temp_tiles_root):
		if tile is Tile:
			if !deploy_tiles.values().has(tile):
				tile.destroy()
	while Tile.flashing_tiles.size() > 0 and Actor.flashing_actors.size() > 0:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	print_debug("Finished flashing board")
