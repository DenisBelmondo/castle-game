@tool
extends Node3D


signal event(p_name: StringName, user_data: Variant)

var physics_exclude: Array[Object]


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name': 'physics_exclude',
			'type': TYPE_ARRAY,
			'hint': PROPERTY_HINT_ARRAY_TYPE,
			'hint_string': '%d/%d:%s' % [ TYPE_OBJECT, PROPERTY_HINT_NODE_TYPE, 'CollisionObject3D,CSGShape3D' ],
			'usage': PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		}
	]
