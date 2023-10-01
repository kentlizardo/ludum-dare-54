extends Node
class_name Board

signal win
signal lose

var entities : Array[BoardEntity] = []

func register_entity(e : BoardEntity):
	entities.append(e)

func unregister_entity(e : BoardEntity):
	entities.remove_at(entities.find(e))

class BoardEvent extends App.Event:
	func _init(do : Callable):
		super(
			Util.EMPTY_CALLABLE,
			do,
			App.board_view.create_view_event(),
		)

