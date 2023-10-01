extends Node2D

class_name BoardView

@onready
var tiles_root : Node2D = get_node("Tiles")
@onready
var actors_root : Node2D = get_node("Actors")

var links : Dictionary = {}

#class BoardViewEvent extends App.Event:
#	func _init(helper : Callable):
#		super(
#			Util.EMPTY_CALLABLE,
#			helper,
#			Util.EMPTY_CALLABLE,
#		)

func flash(entities : Array[BoardEntity]):
	for entity in entities:
		if entity is TileEntity:
			var link = links[entity]
			if link:
				link.flash(entity)
			else:
				var new_link = Tile.new()
				tiles_root.add_child(new_link)
				new_link.flash(entity)
				links[entity] = new_link
		if entity is ActorEntity:
			var link = links[entity]
			if link:
				link.flash(entity)
			else:
				var new_link = Actor.new()
				actors_root.add_child(new_link)
				new_link.flash(entity)
				links[entity] = new_link
	for node in links.values():
		if node.board_entity.board == null:
			node.destroy()

#func create_view_event():
#	return BoardViewEvent.new(flash)

func _ready():
	pass

func _process(delta):
	pass

