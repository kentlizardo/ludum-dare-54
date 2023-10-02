extends Node

const root_scene_path = "/root/HDScene/SubViewportContainer/SubViewport/RootScene"
func root_get_node(path) -> Node:
	return get_node(root_scene_path+"/"+path)

const FPS_DOT : float = 1.0 / 24.0
const TILE_SIZE : int = 16

const TILE_TEMPLATE = preload("res://assets/scenes/game/tiles/_tile_template.tscn")
const ACTOR_TEMPLATE = preload("res://assets/scenes/game/actors/_actor_template.tscn")

const BOARD_LEVEL = preload("res://assets/scenes/game/levels/_board_level.tscn")

enum SELECTION_TYPES {
	TILE = 1 << 0,
	ACTOR = 1 << 1,
}
enum GAME_STATE {EVENTS, IDLE, RUNNING}

static var selected_node : Node = null:
	set(x):
		if selected_node != null:
			selected_node.select_sprite.visible = false
		selected_node = x
		if selected_node != null:
			selected_node.select_sprite.visible = true
	get:
		return selected_node

@onready
var root_scene = get_node(root_scene_path)
@onready
var root_2d = root_get_node("Root2D")
@onready
var root_control = root_get_node("RootControl")
@onready
var root_2d_center = root_2d.get_node("Center")

@onready var background_sprite : Sprite2D = root_2d.get_node("BG")
@onready
var fade_sprite : Sprite2D = root_2d.get_node("Fade")
func fade(now_black : bool):
	var tw = fade_sprite.create_tween()
	if now_black:
		tw.tween_property(fade_sprite, "position:y", -240, 8.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUART).from(240)
	else:
		tw.tween_property(fade_sprite, "position:y", 240, 8.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUART).from(-240)
	await tw.finished

#@onready var left_card : Control = root_control.get_node("LeftCard")
#@onready var left_card_text : RichTextLabel = left_card.get_node("CardText")
#@onready var left_card_actions : Control = root_control.get_node("LeftActions")
#
#@onready var right_card : Control = root_control.get_node("RightCard")
#@onready var right_card_text : RichTextLabel = right_card.get_node("CardText")
#@onready var right_card_actions : Control = root_control.get_node("RightActions")

@onready var dialog_control : Control = root_control.get_node("Dialog")
@onready var dialog_text : RichTextLabel = root_control.get_node("Dialog/Bounds/DialogText")
@onready var dialog_pfp : TextureRect = root_control.get_node("Dialog/Bounds/PFP")
@onready var helper_text : RichTextLabel = root_control.get_node("HelperText")
var hint : String = "":
	set(x):
		hint = x
		helper_text.text = "[center]" + hint + "[/center]"
	get:
		return hint
@onready var voice_player : AudioStreamPlayer2D = root_control.get_node("Dialog/Bounds/PFP/VoicePlayer")
@onready var voice_bit : AudioStream = ResourceLoader.load("res://assets/audio/pawn.wav")

@onready var board_view : BoardView = root_2d.get_node("Center/BoardView")

@onready var button_panel : Control = root_control.get_node("Buttons")
@onready var end_btn : TextureButton = root_control.get_node("Buttons/End")
@onready var confirm_btn : TextureButton = root_control.get_node("Buttons/Confirm")
@onready var cancel_btn : TextureButton = root_control.get_node("Buttons/Cancel")


var starting_level : PackedScene = ResourceLoader.load("res://assets/scenes/game/levels/intro.tscn")
var loaded_level : Node = null
var data : Dictionary = {}
var game_state : GAME_STATE = GAME_STATE.IDLE:
	set(x):
		game_state = x
	get:
		return game_state
#
#const ACTION_CARD = preload("res://assets/scenes/game/actions/action_card.tscn")
#
#var left_subs_keys : Array[String] = []
#var right_subs_keys : Array[String] = []
#var left_card_text_substitutions : Dictionary = {}
#var right_card_text_substitutions : Dictionary = {}
#
#func wrap_meta(meta : String, text : String):
#	return "[url={meta}]{text}[/url]".format({"meta": meta, "text": text})
#
#func load_card(card : Control, card_text: RichTextLabel, action_cards : Control, subs : Dictionary, subs_keys : Array[String], actor : Actor):
#	card.visible = false
#	card_text.text = ""
#	action_cards.visible = false
#	action_cards.get_children().all(func(x:Node): x.queue_free())
#	subs = {}
#	if actor != null:
#		card.visible = true
#		if actor.card_properties.has("subs"):
#			subs = actor.card_properties["subs"]
#		if actor.card_properties.has("simple_text"):
#			card_text.text = actor.card_properties["simple_text"]
#			for possible_key in subs.keys():
#				if subs_keys.has(possible_key): # full text
#					card_text.text = card_text.text.replace(possible_key, wrap_meta(possible_key, possible_key + ": " + subs[possible_key]))
#				else: # simplified
#					card_text.text = card_text.text.replace(possible_key, wrap_meta(possible_key, possible_key))
#		if actor.card_properties.has("actions"):
#			var actions : Array[ActionData] = actor.card_properties.actions
#			action_cards.visible = true
#			for i in actions:
#				var act_card = ACTION_CARD.instantiate()
#				action_cards.add_child(act_card)
#				act_card.loaded_action = i
#		action_cards.visible = true
#		action_cards.get_children().all(func(x:Node): x.queue_free)
#func update_left_card_text(meta : String):
#	if left_subs_keys.has(meta):
#		left_subs_keys.remove_at(left_subs_keys.find(meta))
#	else:
#		left_subs_keys.append(meta)
#	load_card(left_card, left_card_text, left_card_actions, left_card_text_substitutions, left_subs_keys, player_inspect)
#func update_right_card_text(meta : String):
#	if right_subs_keys.has(meta):
#		right_subs_keys.remove_at(right_subs_keys.find(meta))
#	else:
#		right_subs_keys.append(meta)
#	load_card(left_card, left_card_text, left_card_actions, right_card_text_substitutions, right_subs_keys, player_inspect)
#var player_inspect : Actor = null:
#	set(x):
#		player_inspect = x
#		load_card(left_card, left_card_text, left_card_actions, left_card_text_substitutions, left_subs_keys, player_inspect)
#	get:
#		return player_inspect
#var npc_inspect : Actor = null:
#	set(x):
#		npc_inspect = x
#		load_card(right_card, right_card_text, right_card_actions, right_card_text_substitutions, right_subs_keys, npc_inspect)
#	get:
#		return npc_inspect

var selecting : bool = false
var auto_confirm : bool = false
var current_selection_types : int = 0:
	set(x):
		current_selection_types = x
		match current_selection_types:
			0:
				App.hint = "select an option"
			SELECTION_TYPES.TILE:
				App.hint = "select a tile."
			SELECTION_TYPES.ACTOR:
				App.hint = "select a unit."
			SELECTION_TYPES.ACTOR | SELECTION_TYPES.TILE:
				App.hint = "select a unit or tile."
	get:
		return current_selection_types
var current_selection : Array[Variant] = []
func add_to_selection(v : Variant):
	current_selection += [v]
	if auto_confirm:
		confirm_selection()
func remove_from_selection(v : Variant):
	if current_selection.has(v):
		var sel = current_selection.duplicate()
		sel.remove_at(sel.find(v))
		current_selection = sel
	if auto_confirm:
		confirm_selection()

var selection_validate : Callable = Util.EMPTY_CALLABLE # Decides if a selection is valid, e.g. minimum and maximum selections
var choice_validate : Callable = Util.EMPTY_CALLABLE # Decides if an entity should be selectable
var selection_confirmed : Callable = Util.EMPTY_CALLABLE
var selection_canceled : Callable = Util.EMPTY_CALLABLE

func start_selection(selection_flags : int, auto_confirm : bool, confirm : Callable, 
		cancel : Callable = Util.EMPTY_CALLABLE, 
		selection_validate : Callable = Util.EMPTY_CALLABLE, 
		choice_validate : Callable = Util.EMPTY_CALLABLE) -> Array[Variant]:
	reset_selection()
	current_selection_types = selection_flags
	self.auto_confirm = auto_confirm
	self.selection_validate = selection_validate
	self.selection_confirmed = confirm
	self.selection_canceled = cancel
	self.choice_validate = choice_validate
	print_debug("Now selecting " + var_to_str(current_selection_types))
	selecting = true
	while selecting:
		await get_tree().process_frame
	print_debug("Finished selecting")
	return self.current_selection

func start_selection_from(choices : Array[Variant], selection_flags : int, auto_confirm : bool, confirm : Callable, 
		cancel : Callable = Util.EMPTY_CALLABLE,
		selection_validate : Callable = Util.EMPTY_CALLABLE) -> Array[Variant]:
	var choice_validate = func(x):
		return choices.has(x)
	return await start_selection(selection_flags, auto_confirm, confirm, cancel, selection_validate, choice_validate)

func confirm_selection():
	if selection_confirmed != Util.EMPTY_CALLABLE:
		if selection_validate != Util.EMPTY_CALLABLE:
			if !selection_validate.call(current_selection):
				App.hint = "selection is not valid."
				return
		print_debug("Selection confirmed")
		selection_confirmed.call(current_selection)
	reset_selection()
func cancel_selection():
	App.hint = ""
	if selection_canceled != Util.EMPTY_CALLABLE:
		selection_canceled.call()
	reset_selection()

func reset_selection():
	print_debug("Reset selection")
	selecting = false
	auto_confirm = false
	selection_validate = Util.EMPTY_CALLABLE
	selection_confirmed = Util.EMPTY_CALLABLE
	selection_canceled = Util.EMPTY_CALLABLE
	current_selection = []
	current_selection_types = 0

var _events : Array[Event] = []
var _current_event : Event = null:
	set(x):
		_current_event = x
		if _current_event != null:
			_current_event.start()
		refresh_events()
	get:
		return _current_event

func load_level(packed : PackedScene):
	fade_sprite.position.y = 240
	if loaded_level != null:
		loaded_level.queue_free()
		loaded_level = null
	loaded_level = packed.instantiate() 
	root_2d_center.add_child(loaded_level)
	print_debug("Loading level at " + packed.resource_path)

func refresh_events():
	match game_state:
		GAME_STATE.IDLE:
			if _events.size() > 0 or _current_event != null:
				game_state = GAME_STATE.EVENTS
		GAME_STATE.EVENTS:
			if _events.size() == 0 and _current_event == null:
				game_state = GAME_STATE.IDLE
			if _events.size() > 0 and _current_event == null:
				game_state = GAME_STATE.IDLE

func pop_event():
	assert(_current_event == null)
	_current_event = _events.pop_front()
	refresh_events()

func push_event(event : Event):
	if event._push != Util.EMPTY_CALLABLE:
		await event._push.call()
	_events.append(event)
	print_debug("Pushing " + event.get_class())
	refresh_events()

func push_function(do : Callable):
	push_event(Event.new(Util.EMPTY_CALLABLE, do, Util.EMPTY_CALLABLE))


func _ready():
	self.process_priority = -100
	
	confirm_btn.pressed.connect(self.confirm_selection)
	cancel_btn.pressed.connect(self.cancel_selection)
	
#	left_card_text.meta_clicked.connect(update_left_card_text)
#	right_card_text.meta_clicked.connect(update_right_card_text)
	
	close_dialog()
	data["past_events"] = []
	data["actor_templates"] = []
	load_level(starting_level)

var sleep : float = 0.0
var slow_frame : bool = false;

var flashing : bool:
	get:
		return Tile.flashing_tiles.size() > 0 or Actor.flashing_actors.size() > 0
func _process(delta):
	if _events.size() > 0 and _current_event == null:
		pop_event()
	confirm_btn.visible = selection_confirmed != Util.EMPTY_CALLABLE and !auto_confirm
	cancel_btn.visible = selection_canceled != Util.EMPTY_CALLABLE
	button_panel.visible = !flashing
	
	sleep += delta
	if sleep >= App.FPS_DOT:
		slow_frame = true
		sleep = 0
	else:
		slow_frame = false

const CHAR_LENGTH = 0.02
const PITCH_RANGE = 1.0 / 12;
const MAX_WORD_LENGTH : int = 6;
func speak_dialog(dialog : String, pfp : Texture2D, voice_bit : AudioStream):
	dialog_control.visible = true
	dialog_text.text = " " + dialog;
	dialog_text.visible_characters = 0
	if pfp != null:
		dialog_pfp.visible = true
		dialog_pfp.texture = pfp
	var word_complete : bool = true;
	var word_length : int = 0;
	
	var pitch_shift : AudioEffectPitchShift = AudioServer.get_bus_effect(1, 0)
	var og_pitch : float = pitch_shift.pitch_scale
	var last_word_pitch : float = 1.0
	var inflection : int = 0;
	
	while dialog_text.visible_ratio < 1.0:
		var word = get_tree().create_timer(CHAR_LENGTH)
		await word.timeout
		dialog_text.visible_characters += 1
		if dialog.length() > dialog_text.visible_characters:
			var current_char = dialog[dialog_text.visible_characters]
			if current_char != ' ' and word_complete:
				var pitch;
				if inflection == 0:
					pitch = randf_range(-PITCH_RANGE, PITCH_RANGE) + og_pitch
				else:
					pitch = PITCH_RANGE * inflection + last_word_pitch
				pitch_shift.pitch_scale = pitch
				word_complete = false
				last_word_pitch = pitch
				
				voice_player.stream = voice_bit
				voice_player.play()
			else:
				if current_char == ' ':
					word_complete = true
					inflection = 0
				if current_char == '.':
					word_complete = true
					inflection = -1
				if current_char == '!':
					word_complete = true
					inflection = -1
				elif current_char == '?':
					word_complete = true
					inflection = 2
func close_dialog():
	dialog_control.visible = false;
	dialog_pfp.visible = false;

class Event extends RefCounted:
	var _push : Callable
	var _start : Callable
	var _complete : Callable
	
	signal started
	signal completed
	
	func start():
		started.emit()
		if _start != Util.EMPTY_CALLABLE:
			await _start.call()
		completed.emit()
		if App._current_event == self:
			App._current_event = null
	
	func _init(push : Callable , start : Callable, complete : Callable):
		self._push = push
		self._complete = complete
		self._start = start
