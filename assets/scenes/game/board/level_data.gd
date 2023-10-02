extends RefCounted
class_name LevelData

const PLAYER_ACTOR : ActorEntity = preload("res://assets/resources/entities/actors/king.tres")

var chunks : Array[ChunkData] = []
var encounters : Array[EncounterData] = []
var team : Array[ActorTemplateData] = [
	ActorTemplateData.from_actor(PLAYER_ACTOR),
	ActorTemplateData.from_actor(load("res://assets/resources/entities/actors/pawn.tres") ),
	ActorTemplateData.from_actor(load("res://assets/resources/entities/actors/rider.tres") ),
	ActorTemplateData.from_actor(load("res://assets/resources/entities/actors/rook.tres") ),
	ActorTemplateData.from_actor(load("res://assets/resources/entities/actors/sentinel.tres") ),
]
var player_pos : Vector2i:
	get:
		return team[0].pos
	set(x):
		team[0].pos = x
var count_down : int = -1
func _init():
	team[0].pos = Vector2i(-4, -4)

