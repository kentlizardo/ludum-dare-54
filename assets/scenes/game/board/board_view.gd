extends Node2D

class_name BoardView

@onready
var tiles_root : Node2D = get_node("Tiles")
@onready
var actors_root : Node2D = get_node("Actors")

var links : Dictionary = {} # BoardEntity -> Actor/Tile

func flash(entities : Array[BoardEntity]):
	for entity in entities:
		if entity is TileEntity:
			var link = links[entity]
			if link:
				link.flash(entity, false)
			else:
				var new_link = Tile.new()
				tiles_root.add_child(new_link)
				new_link.flash(entity, true)
				links[entity] = new_link
		if entity is ActorEntity:
			var link = links[entity]
			if link:
				link.flash(entity, false)
			else:
				var new_link = Actor.new()
				actors_root.add_child(new_link)
				new_link.flash(entity, true)
				links[entity] = new_link
	for actor in Util.get_children_recursive(actors_root):
		if actor is Actor:
			if !links.values.has(actor):
				actor.destroy()
	for tile in Util.get_children_recursive(tiles_root):
		if tile is Tile:
			if !links.values.has(tile):
				tile.destroy()
