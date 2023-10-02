extends Node
class_name Board

signal win
signal lose

var entities : Array[BoardEntity] = []

func _ready():
	var gen : Callable = App.data["board"]
	gen.call(self)

func register_entity(e : BoardEntity):
	entities.append(e)

func unregister_entity(e : BoardEntity):
	entities.remove_at(entities.find(e))

func board_event(do : Callable) -> App.Event:
	var wrap : Callable = func():
		do.call()
		await App.board_view.flash(entities)
	return App.Event.new(
		Util.EMPTY_CALLABLE,
		do,
		Util.EMPTY_CALLABLE,
	)
