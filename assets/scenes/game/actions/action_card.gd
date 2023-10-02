extends NinePatchRect
class_name ActionCard

const PIP_SCENE = preload("res://assets/scenes/game/actions/pip.tscn")

enum PIP_TYPE {
	BLUE = 0,
	RED = 1,
}

static func pip_tex_region(pip_type : PIP_TYPE) -> Rect2:
	match pip_type:
		PIP_TYPE.BLUE:
			return Rect2(0, 8, 8, 8)
		PIP_TYPE.RED:
			return Rect2(8, 0, 8, 8)
	return Rect2(0, 0, 8, 8)

@export var card_text : RichTextLabel
@export var area_view : Control
@export var area_grid : GridContainer

var pips : Dictionary = {} # Vector2i to Control

var loaded_action : ActionData:
	set(x):
		loaded_action = x
		_load_action(loaded_action)
	get:
		return loaded_action

func set_area(area : Array[Vector2i], pip_type : PIP_TYPE):
	pips.values().all(func(x: Control): x.visible = false)
	for pos in area:
		if pips.has(pos):
			pips[pos].visible = true
			var atlas : AtlasTexture = pips[pos].texture
			atlas.region = pip_tex_region(pip_type)

func hover_started(meta : String):
	if meta == "range":
		if loaded_action.has_range:
			area_view.visible = true
			set_area(loaded_action.range, PIP_TYPE.BLUE)
	if meta == "blast":
		if loaded_action.has_blast:
			area_view.visible = true
			set_area(loaded_action.blast, PIP_TYPE.RED)
func hover_ended(meta : String):
	area_view.visible = false
	set_area([], PIP_TYPE.BLUE)
func meta_click(meta : String):
	if meta == "click":
		Turn._turn.setup_action(loaded_action)

func _load_action(action : ActionData):
	set_area([], PIP_TYPE.BLUE)
	area_view.visible = false
	visible = false
	if action != null:
		visible = true
		var text = "[url=click]{name}[/url]".format({"name": action.name})
		if action.has_range:
			text += " [url=range]RNG[/url]"
		if action.has_blast:
			text += " [url=blast]BLST[/url]"
		card_text.text = text
		print_debug(var_to_str(action))
		

func _ready():
	card_text.meta_clicked.connect(meta_click)
	card_text.meta_hover_started.connect(hover_started)
	card_text.meta_hover_ended.connect(hover_ended)
	for i in range(25):
		var x = i % 5
		var y = i / 5
		var pip : Control = PIP_SCENE.instantiate()
		area_grid.add_child(pip)
		pips[Vector2i(x,  y)] = pip

