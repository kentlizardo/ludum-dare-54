class_name AreaBuilder

const TILE_SHAPE = preload("res://assets/resources/full_tile_shape.tres")

static func create_area_2d_orphan(b_area : Array[Vector2i]) -> Area2D:
	var g_area = Area2D.new()
	for coord in b_area:
		var col_shape = CollisionShape2D.new()
		col_shape.shape = TILE_SHAPE
		col_shape.position = Vector2(coord.x * App.TILE_SIZE, coord.y * App.TILE_SIZE)
		g_area.add_child(col_shape)
	return g_area
