extends Node2D

class_name HeightPivot

const MAX_DELTA_DIST_SQUARED = 4096.0

var old_pos : Vector2 = self.position
var delta_pos : float = 0.0

var shake_value : float = 0.0 # from 0 to 1
func _process(delta):
	delta_pos = (position - old_pos).length_squared()
	shake_value = minf(delta_pos, MAX_DELTA_DIST_SQUARED) * 12.0
	old_pos = position
