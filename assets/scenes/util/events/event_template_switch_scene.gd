extends EventTemplate

class_name EventTemplateSwitchScene

@export
var packed : PackedScene

func create_event() -> App.Event:
	return event_template(packed)

static func event_template(scene : PackedScene) -> App.Event:
	return App.Event.new(
			Util.EMPTY_CALLABLE,
			func ():
				await App.load_level(scene)
				,
			Util.EMPTY_CALLABLE,
		)

	
