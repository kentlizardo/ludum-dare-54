extends Resource

class_name Ability

@export
var name : String = ""
@export
var desc : String = ""

var modify_actions : Callable = Util.EMPTY_CALLABLE # (Array[Action]) -> Array[Action]
var apply_to_actor_entity : Callable = Util.EMPTY_CALLABLE # (ActorEntity)
