extends EventTemplate

class_name EventTemplateFadeBlack

@export
var fade_to_black : bool = false

func create_event() -> App.Event:
	return event_template(fade_to_black, wait_until)

static func event_template(fade_to_black : bool, wait_until : bool) -> App.Event:
	return App.Event.new(
			Util.EMPTY_CALLABLE,
			func ():
				if wait_until:
					await App.fade(fade_to_black)
				else:
					App.fade(fade_to_black)
				,
			Util.EMPTY_CALLABLE,
		)
