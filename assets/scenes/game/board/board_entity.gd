extends Resource

class_name BoardEntity

@export
var helpers : Array[String] = [] # use to assist in animations

var board : Board = null:
	set(x):
		if board != null:
			board.unregister_entity(self)
		board = x
		if board != null:
			board.register_entity(self)
	get:
		return board

func _init(board : Node = null):
	self.board = board

func destroy():
	board = null
