extends Node

class_name Util

const EMPTY_CALLABLE = Callable()

static func get_children_recursive(node : Node) -> Array[Node]:
	assert(node != null)
	return _get_children_recursive(node)

static func _get_children_recursive(node : Node) -> Array[Node]:
	var children = node.get_children()
	for child in children.duplicate():
		children.append_array(_get_children_recursive(child))
	return children

static func get_ancestor_if(node : Node, predicate : Callable) -> Node:
	assert(node != null)
	return _get_ancestor_if(node.get_parent(), predicate)

static func _get_ancestor_if(node : Node, predicate : Callable) -> Node:
	if node == null:
		return node
	if predicate.call(node) == true:
		return node
	return _get_ancestor_if(node.get_parent(), predicate)

static func await_until(predicate : Callable):
	while !predicate.call():
		await App.get_tree().process_frame

static func chebyshev_dist(lhs : Vector2i, rhs : Vector2i) -> int:
	return maxi(abs(rhs.y - lhs.y), abs(rhs.x - lhs.x))

static func pred_if_maximum_array(count : int) -> Callable:
	return func(arr : Array) -> bool: return arr.size() < count

class Batch extends RefCounted:
	signal completed
	var counter : int = 0
	var total : int = -1
	func _init(total : int = 0):
		self.total = total
		self.counter = 0
	func wrap_job_and_add(do : Callable) -> Callable:
		self.total += 1
		return wrap_job(do)
	func wrap_job(do : Callable) -> Callable:
		var j = func():
			await do
			submit()
		return j
	func submit():
		counter += 1
		if counter == total:
			completed.emit()
