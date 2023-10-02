extends EventTemplate

class_name EventTemplateSwitchBG

@export
var texture : Texture2D

func create_event() -> App.Event:
	return event_template(texture)

static func event_template(texture : Texture2D) -> App.Event:
	return App.Event.new(
			Util.EMPTY_CALLABLE,
			func ():
				App.background_sprite.texture = texture,
			Util.EMPTY_CALLABLE,
		)
