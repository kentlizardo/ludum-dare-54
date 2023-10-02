extends Node2D

class_name Tile

const CENTER_OFFSET = Vector2i(8, 8)
const WAKE_UP_RATIO = 0.25
const SHAKE_VEC = Vector2(1, 0)

@export
var tile_sprite : Sprite2D
@export
var tile_under_sprite : Sprite2D
@export
var tile_decal_sprite : Sprite2D
@export
var height_pivot : HeightPivot
@export
var area : Area2D

@onready
var select_sprite : Sprite2D = get_node("HeightPivot/SelectSprite")
@onready
var selected_sprite : Sprite2D = get_node("HeightPivot/SelectedSprite")

@export
var tile_height : int = 0:
	set(x):
		tile_height = x
		var tw = height_pivot.create_tween()
		tw.tween_property(height_pivot, "position:y", int(-tile_height * App.TILE_SIZE * 0.25), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	get:
		return tile_height

@onready
var og_pos : Vector2 = self.position;
var tile_pos : Vector2i:
	get:
		var v : Vector2i = (Vector2i(position) - CENTER_OFFSET) / App.TILE_SIZE
		return v

@onready
var level : Level = Util.get_ancestor_if(self, func(x): return x is Level) as Level;

func flash(e : TileEntity, skip : bool):
	tile_sprite.texture = null
	tile_under_sprite.texture = null
	tile_decal_sprite.texture = null
	if e:
		tile_height = e.height
		position = e.pos * App.TILE_SIZE + CENTER_OFFSET
		tile_sprite.texture = MasterResources.get_tile_sprite(Vector2i(e.terrain_id, e.terrain_variant))
		tile_under_sprite.texture = MasterResources.get_column_sprite(e.terrain_id)
		if e.decal_id != -Vector2i.ONE:
			tile_decal_sprite.texture = MasterResources.get_decal_sprite(e.decal_id)
		if skip:
			position = Tile.CENTER_OFFSET + e.pos * App.TILE_SIZE
		else:
			var tw = create_tween().tween_property(self, "position", Vector2(Tile.CENTER_OFFSET + e.pos * App.TILE_SIZE), 0.3)
			await tw.finished

func _shake(delta):
	if height_pivot.shake_value > 0.01:
		if App.slow_frame:
			tile_sprite.offset = SHAKE_VEC * randi_range(-1, 1)
			tile_under_sprite.offset = SHAKE_VEC * randi_range(-1, 1)
	else:
		tile_sprite.offset = Vector2.ZERO
		tile_under_sprite.offset = Vector2.ZERO

func destroy():
	tile_height = -5
	await get_tree().create_timer(1.0).timeout
	self.queue_free()

func _exit_tree():
	if App.current_selection.has(self):
		App.current_selection.remove_at(App.current_selection.find(self))

func _process(delta):
	area.input_pickable = App.current_selection_types & App.SELECTION_TYPES.TILE != 0
	selected_sprite.visible = App.current_selection.has(self) # slow but easy
	_shake(delta)

func _ready():	
	area.mouse_entered.connect(_on_area_mouse_entered)
	area.mouse_exited.connect(_on_area_mouse_exited)
	area.input_event.connect(_on_area_input_event)
	height_pivot.position.y = 2 * App.TILE_SIZE
	var dist = position.length()
	var x = get_tree().create_timer(1.0 + dist / 32.0)
	await x.timeout
	tile_height = 0

static var selected_tile : Tile = null:
	set(x):
		if selected_tile != null:
			selected_tile.select_sprite.visible = false
		selected_tile = x
		if selected_tile != null:
			selected_tile.select_sprite.visible = true
	get:
		return selected_tile
func toggle_select():
	if App.current_selection.has(self):
		App.current_selection.remove_at(App.current_selection.find(self))
	else:
		App.current_selection.append(self)
func _on_area_input_event(viewport: Node, event:InputEvent, shape_idx:int):
	if App.current_selection_types & App.SELECTION_TYPES.TILE != 0:
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
			if App.current_selection_types & App.SELECTION_TYPES.TILE != 0:
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

