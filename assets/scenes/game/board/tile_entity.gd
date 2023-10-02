extends BoardEntity

class_name TileEntity

static func create_dummy(properties : Dictionary) -> TileEntity:
	var e = TileEntity.new(null)
	for key in properties.keys():
		e.set(key, properties[key])
	return e

var pos : Vector2i = Vector2i.ZERO
var height : int = 0
var terrain_id : int = 0
var terrain_variant : int = -1
var decal_id : Vector2i = -Vector2i.ONE
