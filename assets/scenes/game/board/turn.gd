extends RefCounted
class_name Turn

enum TURN_STATE {
	INSPECTING=0,
	ACTION_SETUP=1,
	ENDED=2,
}

static var _turn : Turn = null

static func start_turn():
	_turn = Turn.new()
static func end_turn():
	_turn = null

var ongoing : bool:
	get:
		return state != TURN_STATE.ENDED
var state : TURN_STATE = TURN_STATE.INSPECTING:
	set(x):
		match state:
			TURN_STATE.INSPECTING:
				App.npc_inspect = null
				App.player_inspect = null
				App.reset_selection()
			TURN_STATE.ACTION_SETUP:
				pass
			TURN_STATE.ENDED:
				pass
		state = x
		match state:
			TURN_STATE.INSPECTING:
				pass
			TURN_STATE.ACTION_SETUP:
				pass
			TURN_STATE.ENDED:
				pass
	get:
		return state

func setup_action(action : ActionData):
	state = TURN_STATE.ACTION_SETUP
	var data = {
		"completed": false,
		"canceled": false,
	}
	if action.has_range:
		App.start_selection_from(
			Board.board.get_tiles_at(action.range),
			App.SELECTION_TYPES.TILE,
			false,
			func(confirmed):
				data["target"] = App.board_view.reverse_tile(App.board_view.confirmed[0]),
			func():
				data["canceled"] = true,
			func(sel):
				return sel.size() == 0,
		)
	while !data.completed:
		if data.canceled:
			state = TURN_STATE.INSPECTING
			return
		await App.get_tree().process_frame
	match action.name:
		"attack":
			pass
		"move":
			action.owner.pos = data["target"].pos
	state = TURN_STATE.INSPECTING
