extends Node

class_name EventTemplateDialog

@export
var message : String = ""
@export
var pfp : Texture2D = null
@export
var voice_bit : AudioStream = null

func create_event() -> App.Event:
	return App.Event.new(
			Util.EMPTY_CALLABLE,
			func ():
				App.speak_dialog(message, pfp, voice_bit)
				var old_pressed : bool = false
				var pressed : bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
				while true:
					pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
					if !pressed and old_pressed:
						break
					await App.get_tree().process_frame
					old_pressed = pressed
				App.close_dialog()
				pass,
			Util.EMPTY_CALLABLE,
		)
