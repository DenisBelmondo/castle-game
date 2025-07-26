extends Attack


const Attack := preload('res://scripts/attack.gd')
const Health := preload('res://scripts/health.gd')
const LocalGameContext := preload('res://scripts/local_game_context.gd')
const PhysicsQuery := preload('res://scripts/physics_query.gd')
const Util := preload('res://scripts/util.gd')

signal intersections_detected(intersections: Array)

@export var _local_game_context: LocalGameContext
@onready var _self_3d: Node3D = self as Object as Node3D
@onready var physics_query: PhysicsQuery = $PhysicsQuery


func _ready() -> void:
	physics_query.should_not_be_excluded_predicate = func (d: Dictionary) -> bool:
		return d.collider not in physics_query.exclude

	physics_query.get_intersection_results_function = func () -> Array:
		var results: Array = []

		for i in 7:
			var p := PhysicsRayQueryParameters3D.create(
				_self_3d.global_position,
				_self_3d.global_position
						- _self_3d.global_basis.z
								.rotated(_self_3d.global_basis.y, randf_range(-PI / 30.0, PI / 30.0))
								.rotated(_self_3d.global_basis.x, randf_range(-PI / 60.0, PI / 60.0))
								* 16)

			p.hit_from_inside = true

			results.append_array(Util.intersect_ray_all_3d(_self_3d.get_world_3d().direct_space_state, p))

		return results


func shoot() -> void:
	var intersection_results = physics_query.get_intersection_results()

	if intersection_results is not Array:
		return

	intersection_results = intersection_results as Array[Dictionary]

	for intersection_result in intersection_results:
		var o: Object = intersection_result.collider
		var health = Health.get_from(o)

		if is_instance_valid(health):
			health = health as Health
			health.damage(30)
			#continue

		var puff: Node3D = preload('res://scenes/effects/spark_puff.tscn').instantiate()
		var position = intersection_result.get(&'position')
		var normal = intersection_result.get(&'normal')

		if position is Vector3:
			_local_game_context.current_scene_root.add_child.call_deferred(puff)
			puff.set_deferred(&'global_position', intersection_result.position)
			puff.set_deferred(&'emitting', true)

			if normal is Vector3:
				puff.set_deferred(&'global_position', intersection_result.position + intersection_result.normal / 10.0)
				puff.look_at.call_deferred(intersection_result.position + intersection_result.normal)

	intersections_detected.emit(intersection_results)
