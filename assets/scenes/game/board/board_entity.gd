extends RefCounted

class_name BoardEntity

var board : Node = null:
	set(x):
		if board:
			board.unregister_entity(self)
		board = x
		if board:
			board.register_entity(self)
	get:
		return board

func _init(board : Node):
	board = board

func destroy():
	board = null
