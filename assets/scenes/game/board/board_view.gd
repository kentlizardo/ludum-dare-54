extends Node2D

class_name BoardView

@onready
var tiles_root : Node2D = get_node("Tiles")
@onready
var actors_root : Node2D = get_node("Actors")

var links : Dictionary = {} # BoardEntity -> Actor/Tile

func flash(board : Board):
	# Create Links
	for entity in board.entities:
		print_debug(var_to_str(entity))
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
	# Remove links that aren't in level_data
	for key in links.keys():
		if !board.entities.has(key):
			var link = links[key]
			link.destroy()
			links.erase(key)
	# Change existing links
	for entity in board.entities:
		if links.has(entity):
			if entity is ActorEntity:
				var actor : Actor = links[entity]
				actor.flash(entity, false)
			if entity is TileEntity:
				var tile : Tile = links[entity]
				tile.flash(entity, false)
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
	print_debug("Finished flashing board")
