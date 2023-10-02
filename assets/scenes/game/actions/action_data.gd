extends RefCounted

class_name ActionData

var name : String = ""
var owner : ActorEntity = null
var range : Array[Vector2i] = []
var has_range : bool:
	get: return !range.is_empty()
var blast : Array[Vector2i] = []
var has_blast : bool:
	get: return !blast.is_empty()

