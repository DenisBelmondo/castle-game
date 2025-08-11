#
# a class with some static methods that have no relation to gameplay and instead
# are just supplementary functions for godot itself.
#


# [TODO]: is this necessary?
## Safely chooses between calling `parent.add_child` or `child.reparent`
## depending on whether or not it's in the tree.
static func reparent_or_add_child(child: Node, parent: Node) -> void:
	var f := parent.add_child.bind(child)

	if child.is_inside_tree():
		f = child.reparent.bind(parent)

	# i take care of deferring the call because doing it at the call site mucks
	# up the stack trace.
	f.call_deferred()


## Recursively finds children of a node as long as they satisfy `predicate`
## (a callable taking in a child node and returning a boolean based on some
## condition).
static func find_children(node: Node, predicate: Callable, recursive: bool = true, owned: bool = true) -> Array[Node]:
	var results: Array[Node]
	return _find_children(results, node, predicate, recursive, owned)


## A wrapper for `PhysicsDirectSpaceState3D.intersect_ray` that allows users to
## query multiple hits along a ray.
static func intersect_ray_all_3d(direct_space_state: PhysicsDirectSpaceState3D, params: PhysicsRayQueryParameters3D, max_results: int = 32) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var exclude: Array[RID] = params.exclude.duplicate()

	results.resize(max_results)
	exclude.resize(maxi(exclude.size(), max_results))

	var num_results := 0

	for i in max_results:
		params.exclude = exclude

		var result := direct_space_state.intersect_ray(params)

		if result.is_empty():
			break

		results[num_results] = result
		exclude.push_back(result.rid)
		num_results += 1

	# [TODO]: worth doing this?
	results.resize(num_results)

	return results


## Takes results returned from `direct_space_state.intersect_*`-family of
## functions and filters them against a blacklist `exclude` based on object
## instead of RID.
static func filter_physics_query_by_object(physics_query_results: Array, exclude: Array[Object], result_object_field_name: StringName = &'collider') -> Array:
	return physics_query_results.filter(func (v) -> bool:
			return v[result_object_field_name] not in exclude)


#
# internal
#


static func _find_children(results: Array[Node], node: Node, predicate: Callable, recursive: bool = true, owned: bool = true) -> Array[Node]:
	for c in node.get_children():
		if owned and not is_instance_valid(c.owner):
			continue

		if predicate.call(c) == true:
			results.append(c)

		if recursive:
			_find_children(results, c, predicate, recursive, owned)

	return results
