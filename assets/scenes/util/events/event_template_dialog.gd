extends Node

class_name EventTemplateDialog

@export
var message : String = ""
@export
var pfp : Texture2D = null
@export
var voice_bit : AudioStream = null

func create_event() -> App.Event:
	return App.DialogEvent.new(message, pfp, voice_bit)
