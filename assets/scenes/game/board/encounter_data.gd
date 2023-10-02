extends RefCounted
class_name EncounterData

enum ENCOUNTER_TYPE { 
	BASIC,
	COMBAT,
	SPECIAL,
}

var type : ENCOUNTER_TYPE = ENCOUNTER_TYPE.BASIC
var on_meet : Callable = Util.EMPTY_CALLABLE
var pos : Vector2i = Vector2i.ZERO
var dummy_props : Dictionary:
	get:
		return {
			"pos": pos,
			
		}
func _init(type : ENCOUNTER_TYPE, on_meet : Callable):
	self.type = type
	self.on_meet = on_meet
func meet():
	if on_meet != Util.EMPTY_CALLABLE:
		on_meet.call(self)
	match type:
		ENCOUNTER_TYPE.BASIC:
			pass # add node, await until node is complete/readied.
		ENCOUNTER_TYPE.SPECIAL:
			pass # load level?
		ENCOUNTER_TYPE.COMBAT:
			App.load_level(App.BOARD_LEVEL)
