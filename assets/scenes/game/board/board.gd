extends Node
class_name Board

signal win
signal lose

var entities : Array[BoardEntity] = []

func _ready():
	App.data["board"].call(self)
	App.push_event(setup_board_event)

func _process(delta):
	if App.game_state == App.GAME_STATE.IDLE:
		App.push_event(player_turn_event())

enum TURN_STATE {
	INSPECTING=0,
	ACTION_SETUP=1,
	ENDED=2,
}
class Turn extends RefCounted:
	var state : TURN_STATE = TURN_STATE.INSPECTING:
		set(x):
			match state:
				TURN_STATE.INSPECTING:
#					func start_selection(selection_flags : int, confirm : Callable, 
#						cancel : Callable = Util.EMPTY_CALLABLE, 
#						selection_validate : Callable = Util.EMPTY_CALLABLE, 
#						choice_validate : Callable = Util.EMPTY_CALLABLE) -> Array[Variant]:
#							pass
#					App.start_selection(
#
#					)
					pass
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


func player_turn_event() -> App.Event:
	return App.Event.new(
		Util.EMPTY_CALLABLE,
		func():
			var turn : Turn = Turn.new()
			while turn.state != TURN_STATE.ENDED:
				await get_tree().process_frame
			await App.board_view.flash(self),
		Util.EMPTY_CALLABLE,
	)

func register_entity(e : BoardEntity):
	entities.append(e)

func unregister_entity(e : BoardEntity):
	entities.remove_at(entities.find(e))

var setup_board_event = App.Event.new(
	Util.EMPTY_CALLABLE,
	func():
		var level_data : LevelData = App.data["levels"]
		level_data.team.all(func(x : ActorTemplateData): x.token_actor = null)
		await App.board_view.flash(self)
		var props = {"val": 0,
			"deploy_satisfied": level_data.team[0].token_actor != null,
			"deployed": false
		}
		var deploy_call = func():
			if props.deploy_satisfied:
				App.reset_selection()
				props.deployed = true
				App.end_btn.visible = false
			else:
				props.val += 1
				if props.val < 5:
					App.hint = "your king must be deployed before battle."
				else:
					App.hint = "only a king who is a coward will not fight with his troops."
		App.end_btn.visible = true
		App.end_btn.pressed.connect(deploy_call)
		while !props.deployed:
			App.hint = "select a unit to deploy."
			var deploy_actors = App.board_view.deploy_links.values()
			for member in level_data.team:
				if member.token_actor != null:
					deploy_actors.append(App.board_view.links[member.token_actor])
			var deployment : Dictionary = {
				"actor": null,
				"tile": null,
			}
			await App.start_selection_from(
				deploy_actors,
				App.SELECTION_TYPES.ACTOR,
				true,
				func(confirmed_selection): # confirm
					deployment.actor = confirmed_selection[0]
					,
				func(): # cancel
					pass,
				func(selection): # validate
					return selection.size() == 1,
			)
			if deployment.actor == null:
				continue
			var possible_tile_nodes : Array[Node] = Util.get_children_recursive(App.board_view.tiles_root)
			possible_tile_nodes.append_array(Util.get_children_recursive(App.board_view.temp_tiles_root))
			var all_tiles = possible_tile_nodes.filter(func(x): return x is Tile)
			App.hint = "select a tile."
			await App.start_selection_from(
				all_tiles,
				App.SELECTION_TYPES.TILE,
				true,
				func(confirmed_selection): # confirm
					deployment.tile = confirmed_selection[0]
					,
				func(): # cancel
					pass,
				func(selection): # validate
					return selection.size() == 1,
			)
			if deployment.tile == null:
				continue
			App.hint = ""
			if deployment.tile != null and deployment.actor != null:
				var actor_source : Variant = App.board_view.reverse_actor(deployment.actor)
				var tile_source : Variant = App.board_view.reverse_tile(deployment.tile)
				if actor_source is ActorTemplateData: # yet to be deployed
					if tile_source is ActorTemplateData: # invalid, moving deployed to deployed
						continue
					elif tile_source is TileEntity: # deployed to tangible tile
						var token : ActorEntity = actor_source.real_actor.duplicate()
						token.pos = tile_source.pos
						actor_source.token_actor = token
						token.board = self
						tile_source.pos
				elif actor_source is ActorEntity: # selecting an already deployed_actor
					if tile_source is ActorTemplateData: # undeploying
						actor_source.token_actor = null
					elif tile_source is TileEntity: # switching locations
						actor_source.pos = tile_source.pos
				await App.board_view.flash(self)
			props.deploy_satisfied = level_data.team[0].token_actor != null
		App.hint = ""
		await App.board_view.flash(self)
		,
	Util.EMPTY_CALLABLE,
	)
func action_event(do : Callable) -> App.Event:
	return App.Event.new(
		Util.EMPTY_CALLABLE,
		await App.board_view.flash(self),
		Util.EMPTY_CALLABLE,
	)

func board_event(do : Callable) -> App.Event:
	var wrap : Callable = func():
		if do != Util.EMPTY_CALLABLE:
			do.call()
		await App.board_view.flash(self)
	return App.Event.new(
		Util.EMPTY_CALLABLE,
		wrap,
		Util.EMPTY_CALLABLE,
	)
