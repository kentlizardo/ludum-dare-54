extends Node2D

class_name Level

signal level_completed

@onready
var tiles = get_node("Tiles")

var actors : Array[Actor] = []
var objectives : Array[Objective]
var players_turn : bool = true

class Objective extends RefCounted:
	var description : String = ""
	var predicate : Callable = Util.EMPTY_CALLABLE
	var completed : bool = false;
	func _init(desc : String, predicate : Callable):
		self.predicate = predicate
		self.description = desc
	func check():
		if predicate.call() == true:
			completed = true

func _process(delta):
	if objectives.size() == 0:
		return
	var incomplete = objectives.filter(func(x : Objective):
		!x.completed)
	if incomplete.size() == 0:
		level_completed.emit()
		return
	for objective in incomplete:
		if !objective.completed:
			objective.check()

#class TurnEvent extends Event:
#	func _init():
#		var start = func():
#			if App.loaded_level.players_turn:
#				App.start_turn()
#				await App.turn_ended
#			else:
#				pass
#			App.loaded_level.players_turn = !App.loaded_level.players_turn
#		super(Util.EMPTY_CALLABLE, start, Util.EMPTY_CALLABLE)
