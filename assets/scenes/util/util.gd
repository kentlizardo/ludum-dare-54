extends Node

class_name Util

static func get_children_recursive(node : Node) -> Array[Node]:
	assert(node != null)
	return _get_children_recursive(node)

static func _get_children_recursive(node : Node) -> Array[Node]:
	var children = node.get_children()
	for child in children.duplicate():
		children.append(child)
		children.append_array(_get_children_recursive(child))
	return children;
