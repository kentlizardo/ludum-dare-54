extends Node

class_name EventGroup

func queue_all_events():
	for event in create_all_events():
		App.push_event(event)

func create_all_events() -> Array[App.Event]:
	var r_children = Util.get_children_recursive(self)
	var events : Array[App.Event] = []
	for child in r_children:
		var etc : App.Event = has_event_then_call(child)
		if etc != null:
			events.append(etc)
	return events

func has_event_then_call(template_node : Node) -> App.Event:
	if template_node.has_method("create_event"):
		var event_obj : App.Event = template_node.call("create_event")
		return event_obj
	return null
