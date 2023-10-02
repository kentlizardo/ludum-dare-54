extends BoardEntity

class_name ActorEntity

enum CONTROL {
	IDLE = 0,
	PLAYER = 1,
	ENEMY = 2,
}

static func create_dummy(properties : Dictionary) -> ActorEntity:
	var e = ActorEntity.new(null)
	for key in properties.keys():
		e.set(key, properties[key])
	return e

@export
var pos : Vector2i = Vector2i.ZERO
@export
var name : String = ""
@export
var graphic : int = 63
@export
var controlled : CONTROL = CONTROL.IDLE
@export
var inspectable : bool = true
@export
var health : int = 0
@export
var attack : int = 0
@export
var blast_radius : int = 0
@export
var move_speed : int = 1
@export
var move_adj : bool = true
@export
var move_dia : bool = true
@export
var horse_movement : bool = false
@export
var abilities : Array[Ability] = []

var attacked : bool = false
var move_left : int = move_speed
var tired : bool:
	get:
		return move_left <= 0 and attacked

func get_adjacent_tiles(pos : Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1),
		pos + Vector2i(-1, 0),
		pos + Vector2i(1, 0),
	]
func get_diagonal_tiles(pos : Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(1, 1),
		pos + Vector2i(1, -1),
		pos + Vector2i(-1, 1),
		pos + Vector2i(-1, -1),
	]

func get_move_tiles() -> Array:
	var pseudo_set = {}
	if move_dia:
		for i in get_diagonal_tiles(pos):
			pseudo_set[i] = 0
	if move_adj:
		for i in get_adjacent_tiles(pos):
			pseudo_set[i] = 0
	if horse_movement:
		for i in range(move_speed):
			for past in pseudo_set.keys():
				if move_dia:
					for j in get_diagonal_tiles(past):
						pseudo_set[j] = 0
				if move_adj:
					for j in get_adjacent_tiles(past):
						pseudo_set[j] = 0
		for i in pseudo_set.keys():
			var rel = i - pos
			if ((rel.x == 0 and rel.y != 0) or (rel.x != 0 and rel.y == 0)):
				pseudo_set.erase(i)
	return pseudo_set.keys()

#func get_move():
#	var act := ActionData.new()
#	act.owner = self
#	act.name = "move"
#	act.range = get_move_tiles()
#	print_debug(act.range)
#	return act
#func get_attack():
#	var act := ActionData.new()
#	act.owner = self
#	act.name = "attack"
#	act.range = get_move_tiles()
#	print_debug(act.range)
#	return act
#
#func get_actions() -> Array[ActionData]:
#	var actions : Array[ActionData] = []
#	if move_left > 0:
#		actions.append(get_move())
#	if attack > 0:
#		actions.append(get_attack())
#	return actions
