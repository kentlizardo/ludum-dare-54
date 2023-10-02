extends Node

const root_scene_path = "/root/HDScene/SubViewportContainer/SubViewport/RootScene"
func root_get_node(path) -> Node:
	return get_node(root_scene_path+"/"+path)

const FPS_DOT : float = 1.0 / 24.0
const TILE_SIZE : int = 16

const TILE_TEMPLATE = preload("res://assets/scenes/game/tiles/_tile_template.tscn")
const ACTOR_TEMPLATE = preload("res://assets/scenes/game/actors/_actor_template.tscn")

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

@onready
var fade_sprite : Sprite2D = root_2d.get_node("Fade")

@onready
var dialog_control : Control = root_control.get_node("Dialog")
@onready
var dialog_text : RichTextLabel = root_control.get_node("Dialog/Bounds/DialogText")
@onready
var dialog_pfp : TextureRect = root_control.get_node("Dialog/Bounds/PFP")
@onready
var helper_text : RichTextLabel = root_control.get_node("HelperText")
var hint : String = "":
	set(x):
		hint = x
		helper_text.text = "[center]" + hint + "[/center]"
	get:
		return hint
@onready
var voice_player : AudioStreamPlayer2D = root_control.get_node("Dialog/Bounds/PFP/VoicePlayer")

@onready
var board_view : BoardView = root_2d.get_node("Center/BoardView")

@onready
var end_btn : TextureButton = root_control.get_node("Buttons/End")
@onready
var confirm_btn : TextureButton = root_control.get_node("Buttons/Confirm")
@onready
var cancel_btn : TextureButton = root_control.get_node("Buttons/Cancel")

# Resources
var starting_level : PackedScene = ResourceLoader.load("res://assets/scenes/game/levels/intro.tscn")
@onready
var voice_bit : AudioStream = ResourceLoader.load("res://assets/audio/pawn.wav")

var loaded_level : Node = null
var data : Dictionary = {}
var game_state : GAME_STATE = GAME_STATE.IDLE:
	set(x):
		game_state = x
	get:
		return game_state

var selecting : bool = false
var current_selection_types : int = 0
var current_selection : Array[Variant] = []
var selection_validate : Callable = Util.EMPTY_CALLABLE # Decides if a selection is valid, e.g. minimum and maximum selections
var choice_validate : Callable = Util.EMPTY_CALLABLE # Decides if an entity should be selectable
var selection_confirmed : Callable = Util.EMPTY_CALLABLE
var selection_canceled : Callable = Util.EMPTY_CALLABLE

signal turn_ended
var turn_ongoing : bool = false
func start_turn():
	print_debug("Turn started")
	turn_ongoing = true
	end_btn.pressed.connect(end_turn)
func end_turn():
	print_debug("Turn ended")
	turn_ongoing = false
	end_btn.pressed.disconnect(end_turn)
	turn_ended.emit()

func start_selection(selection_flags : int, confirm : Callable, 
		cancel : Callable = Util.EMPTY_CALLABLE, 
		selection_validate : Callable = Util.EMPTY_CALLABLE, 
		choice_validate : Callable = Util.EMPTY_CALLABLE):
	reset_selection()
	current_selection_types = selection_flags
	self.selection_validate = selection_validate
	self.selection_confirmed = confirm
	self.selection_canceled = cancel
	self.choice_validate = choice_validate
	print_debug("Now selecting " + var_to_str(current_selection_types))
	selecting = true

func start_selection_from(choices : Array[Variant], selection_flags : int, confirm : Callable, 
		cancel : Callable = Util.EMPTY_CALLABLE,
		selection_validate : Callable = Util.EMPTY_CALLABLE):
	var choice_validate = func(x):
		return choices.has(x)
	start_selection(selection_flags, confirm, cancel, choice_validate, selection_validate)

func confirm_selection():
	if selection_confirmed != Util.EMPTY_CALLABLE:
		if selection_validate != Util.EMPTY_CALLABLE:
			if !selection_validate.call(current_selection):
				return
		selection_confirmed.call(current_selection)
	reset_selection()
func cancel_selection():
	if selection_canceled != Util.EMPTY_CALLABLE:
		selection_canceled.call()
	reset_selection()

func reset_selection():
	selecting = false
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

func _ready():
	self.process_priority = -100
	
	confirm_btn.pressed.connect(self.confirm_selection)
	cancel_btn.pressed.connect(self.cancel_selection)
	
	close_dialog()
	data["past_events"] = []
	data["actor_templates"] = []
	data["move_speed"] = 1
	load_level(starting_level)
#	speak_dialog("Hi! Hello! Squire Ponn at your service! How are you?", voice_bit)

var sleep : float = 0.0
var slow_frame : bool = false;
var fade_accel : float = 0
func _process(delta):
	end_btn.visible = self.turn_ongoing and !self.selecting
	confirm_btn.visible = selection_confirmed != Util.EMPTY_CALLABLE
	cancel_btn.visible = selection_canceled != Util.EMPTY_CALLABLE
	
	sleep += delta
	if sleep >= App.FPS_DOT:
		slow_frame = true
		sleep = 0
	else:
		slow_frame = false
	
	if slow_frame:
		fade_accel += 0.02
		fade_sprite.position.y += fade_accel
#	if game_state == GAME_STATE.IDLE:
#		push_event(TurnEvent.new())
	if _events.size() > 0 and _current_event == null:
		pop_event()

const CHAR_LENGTH = 0.02
const PITCH_RANGE = 1.0 / 12;
const MAX_WORD_LENGTH : int = 6;
func speak_dialog(dialog : String, pfp : Texture2D, voice_bit : AudioStream):
	dialog_control.modulate.a = 1.0;
	dialog_text.text = dialog;
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
	dialog_control.modulate.a = 0.0;
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
