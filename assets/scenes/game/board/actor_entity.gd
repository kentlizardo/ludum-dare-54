extends BoardEntity

class_name ActorEntity

enum CONTROL {
	IDLE = 0,
	PLAYER = 1,
	ENEMY = 2
}

static func create_dummy(properties : Dictionary) -> ActorEntity:
	var e = ActorEntity.new(null)
	for key in properties.keys():
		e.set(key, properties[key])
	return e

@export
var pos : Vector2i = Vector2i.ZERO
@export
var graphic : int = 63
@export
var controlled : CONTROL = CONTROL.IDLE
@export
var health : int = 0
@export
var attack : int = 0
@export
var abilities : Array[Ability] = []

func get_actions() -> Array:
	return []
