extends Node

const root_scene = "/root/HDScene/SubViewportContainer/SubViewport/RootScene/"
func root_get_node(path) -> Node:
	return get_node(root_scene+path)

const FPS_DOT : float = 1.0 / 24.0
const TILE_SIZE : int = 16

@onready
var root_2d = root_get_node("Root2D")
@onready
var root_control = root_get_node("RootControl")
