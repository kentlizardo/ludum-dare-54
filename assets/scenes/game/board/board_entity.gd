extends Resource

class_name BoardEntity

@export
var helpers : Array[String] = [] # use to assist in animations

var board : Node = null:
	set(x):
		if board:
			board.unregister_entity(self)
		board = x
		if board:
			board.register_entity(self)
	get:
		return board

func _init(board : Node = null):
	self.board = board

func destroy():
	board = null
