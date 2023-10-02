extends Node
class_name EventTemplateRespawn

@export
var tiles_root : Node2D

func create_event() -> App.Event:
	return event_template(tiles_root)

static func event_template(tiles_root : Node2D) -> App.Event:
	return App.Event.new(
			Util.EMPTY_CALLABLE,
			func ():
				for i in range(8):
					for j in range(8):
						var grid_pos = Vector2i(i - 4, j - 4)
						var tile : Tile = App.TILE_TEMPLATE.instantiate()
						tiles_root.add_child(tile)
						if (i + j) % 2 == 0:
							tile.flash(TileEntity.create_dummy({
								"pos": grid_pos,
								"terrain_id": 1,
							}), false)
						else:
							tile.flash(TileEntity.create_dummy({
								"pos": grid_pos,
								"terrain_id": 2,
							}), false)
				while App.flashing:
					await App.get_tree().process_frame,
			Util.EMPTY_CALLABLE,
		)
