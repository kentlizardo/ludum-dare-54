extends Node2D

class_name Actor

@export var actor_sprite : Sprite2D
@export var label : RichTextLabel
@export var selected_sprite : Sprite2D
@export var select_sprite : Sprite2D
@export var inspect_right_sprite : Sprite2D
@export var inspect_left_sprite : Sprite2D

@onready
var area : Area2D = get_node("Area2D")

const LABEL_F = "[color=red]{attack}[/color]/[color=green]{health}[/color] [color=grey]{move_left}[/color]"

var controlled : bool = false
var inspectable : bool = false
var card_properties : Dictionary = {}

static var flashing_actors : Array[Actor] = []
func flash(ent : ActorEntity, skip : bool):
	controlled = false
	inspectable = false
	shaking = false
	card_properties = {}
	flashing_actors.append(self)
	label.text = ""
	if ent.helpers.has("damaged"):
		blink_duration += 1.0
	if ent:
#		card_properties.simple_text = """{name}
#ATK:{attack}
#HP:{health}\n""".format(Util.create_simple_property_dict(ent))
#		card_properties.subs = {}
#		for act in ent.abilities:
#			card_properties.subs[act.name] = act.desc
#			card_properties.simple_text += "\n" + act.name
#		card_properties["actions"] = ent.get_actions()
		actor_sprite.texture = MasterResources.get_actor_sprite(ent.graphic)
		shaking = !ent.attacked
		if ent.health > 0 or ent.attack > 0:
			var t = LABEL_F.format(Util.create_simple_property_dict(ent))
			label.text = "[center]" + t + "[/center]"
		controlled = ent.controlled
#		inspectable = ent.inspectable
		if skip:
			position = Tile.CENTER_OFFSET + ent.pos * App.TILE_SIZE
		else:
			var tw = create_tween().tween_property(self, "position", Vector2(Tile.CENTER_OFFSET + ent.pos * App.TILE_SIZE), 0.3)
			await tw.finished
	ent.helpers = []
	flashing_actors.remove_at(flashing_actors.find(self))

const SHAKE_VEC = Vector2(1, 0)
var shaking : bool = false
var shaking_sleep : int = 0

var blink_effect_duration : float = 0
var blink_duration : int = 2
var blink : int = 0

func destroy():
	self.queue_free()

func _exit_tree():
	if flashing_actors.has(self):
		flashing_actors.remove_at(flashing_actors.find(self))
	App.remove_from_selection(self)

func _process(delta : float):
	selected_sprite.visible = App.current_selection.has(self) # Slow but fast implementation
	area.input_pickable = App.current_selection_types & App.SELECTION_TYPES.ACTOR != 0
#	inspect_left_sprite.visible = App.player_inspect == self
#	inspect_right_sprite.visible = App.npc_inspect == self

	if shaking:
		if App.slow_frame:
			shaking_sleep += 1
			if shaking_sleep >= 4:
				shaking_sleep = 0
				actor_sprite.offset = SHAKE_VEC * randi_range(-1, 1)
	else:
		actor_sprite.offset = Vector2.ZERO
	if blink_effect_duration > 0:
		blink_effect_duration -= delta
		if App.slow_frame:
			blink += 1
			if blink >= blink_duration:
				actor_sprite.visible = !actor_sprite.visible
				blink = 0
	else:
		actor_sprite.visible = true
	if Input.is_action_just_released("ui_accept"):
		blink_effect_duration += 1.0;

func _ready():
	area.mouse_entered.connect(_on_area_mouse_entered)
	area.mouse_exited.connect(_on_area_mouse_exited)
	area.input_event.connect(_on_area_input_event)
func toggle_select():
	if App.current_selection.has(self):
		App.remove_from_selection(self)
	else:
		App.add_to_selection(self)
func _on_area_input_event(viewport: Node, event:InputEvent, shape_idx:int):
	if App.current_selection_types & App.SELECTION_TYPES.ACTOR != 0:
		if event is InputEventMouseButton:
			var m_event = event as InputEventMouseButton
			if !m_event.pressed:
				if App.current_selection.has(self):
					toggle_select()
				else:
					if App.choice_validate != Util.EMPTY_CALLABLE:
						if App.choice_validate.call(self):
							toggle_select()
					else:
						toggle_select()
		if event is InputEventMouseMotion:
			if App.choice_validate != Util.EMPTY_CALLABLE:
				if App.choice_validate.call(self):
					App.selected_node = self
			else:
				App.selected_node = self
func _on_area_mouse_entered():
	pass
func _on_area_mouse_exited():
	if App.selected_node == self:
		App.selected_node = null
