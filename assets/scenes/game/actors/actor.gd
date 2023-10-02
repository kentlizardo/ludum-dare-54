extends Node2D

class_name Actor

@export
var actor_sprite : Sprite2D
@export
var label : RichTextLabel

@onready
var select_sprite : Sprite2D = create_sel_sprite()
func create_sel_sprite() -> Sprite2D:
	var new_sprite : Sprite2D = actor_sprite.duplicate()
	actor_sprite.add_child(new_sprite)
	var c = (new_sprite as CanvasItem)
	c.show_behind_parent = true
	new_sprite.texture = new_sprite.texture.duplicate()
	var at = new_sprite.texture as AtlasTexture
	at.region.position.y += 16
	new_sprite.visible = false
	return new_sprite

@onready
var selected_sprite : Sprite2D = get_node("SelectedSprite")

@onready
var area : Area2D = get_node("Area2D")

const LABEL_F = "{attack}/{health}"

static var flashing_actors : Array[Actor] = []
func flash(ent : ActorEntity, skip : bool):
	flashing_actors.append(self)
	label.text = ""
	if ent:
		actor_sprite.texture = MasterResources.get_actor_sprite(ent.graphic)
		if ent.health > 0 or ent.attack > 0:
			var t = LABEL_F.format(Util.create_simple_property_dict(ent))
			label.text = t
		if skip:
			position = Tile.CENTER_OFFSET + ent.pos * App.TILE_SIZE
		else:
			var tw = create_tween().tween_property(self, "position", Vector2(Tile.CENTER_OFFSET + ent.pos * App.TILE_SIZE), 0.3)
			await tw.finished
	flashing_actors.remove_at(flashing_actors.find(self))

var sleep : float = 0
var blink_effect_duration : float = 0
var blink_duration : int = 2
var blink : int = 0

func destroy():
	self.queue_free()

func _exit_tree():
	if App.current_selection.has(self):
		App.current_selection.remove_at(App.current_selection.find(self))

func _process(delta : float):
	selected_sprite.visible = App.current_selection.has(self) # Slow but fast implementation
	area.input_pickable = App.current_selection_types & App.SELECTION_TYPES.ACTOR != 0
	
	if blink_effect_duration > 0:
		sleep += delta
		blink_effect_duration -= delta
		if sleep >= App.FPS_DOT:
			sleep = 0
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
		App.current_selection.remove_at(App.current_selection.find(self))
	else:
		App.current_selection.append(self)
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
