extends Node
class_name Board

signal win
signal lose

var entities : Array[BoardEntity] = []

func _ready():
	App.data["board"].call(self)
	App.push_event(board_event(Util.EMPTY_CALLABLE))

func register_entity(e : BoardEntity):
	entities.append(e)

func unregister_entity(e : BoardEntity):
	entities.remove_at(entities.find(e))

func board_event(do : Callable) -> App.Event:
	var wrap : Callable = func():
		if do != Util.EMPTY_CALLABLE:
			do.call()
		await App.board_view.flash(self)
	return App.Event.new(
		Util.EMPTY_CALLABLE,
		wrap,
		Util.EMPTY_CALLABLE,
	)
