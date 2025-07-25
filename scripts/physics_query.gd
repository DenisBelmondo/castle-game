@tool
extends Node3D


var exclude: Array[Object]

var should_not_be_excluded_predicate: Callable = func (o: Object) -> bool:
	return o not in exclude

var get_intersection_results_function: Callable


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name': 'exclude',
			'type': TYPE_ARRAY,
			'hint': PROPERTY_HINT_ARRAY_TYPE,
			'hint_string': '%d/%d:%s' % [ TYPE_OBJECT, PROPERTY_HINT_NODE_TYPE, 'CollisionObject3D,CSGShape3D' ],
			'usage': PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
	]


func get_intersection_results() -> Array:
	var results = get_intersection_results_function.call()

	assert(results is Array, 'get_intersection_results_function did not return an array when called.')
	results = results as Array

	return results.filter(should_not_be_excluded_predicate)
