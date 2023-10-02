extends RefCounted
class_name ActorTemplateData 

var pos : Vector2i = Vector2i.ZERO
var real_actor : ActorEntity = null # better described as base_actor
var token_actor : ActorEntity = null # actor that gets deployed and duplicated

var dummy_props : Dictionary:
	get:
		if real_actor:
			var dict = Util.create_simple_property_dict(real_actor)
			return dict
		else: return {}
static func from_actor(b : ActorEntity) -> ActorTemplateData:
	var template = ActorTemplateData.new()
	template.real_actor = b.duplicate()
	return template
