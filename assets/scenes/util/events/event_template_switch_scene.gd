extends Node

class_name EventTemplateSwitchScene

@export
var packed : PackedScene

func create_event() -> App.Event:
	return App.Event.new(
			Util.EMPTY_CALLABLE,
			func ():
				App.load_level(packed)
				,
			Util.EMPTY_CALLABLE,
		)
