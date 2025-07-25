extends Node3D


const Health := preload('res://scripts/health.gd')
const PhysicsQuery := preload('res://scripts/physics_query.gd')
const Util := preload('res://scripts/util.gd')

signal intersections_detected(intersections: Array)

@onready var physics_query: PhysicsQuery = $PhysicsQuery


func _ready() -> void:
	physics_query.should_not_be_excluded_predicate = func (d: Dictionary) -> bool:
		return d.collider not in physics_query.exclude

	physics_query.get_intersection_results_function = func () -> Array:
		var p := PhysicsRayQueryParameters3D.create(
			global_position,
			global_position - global_basis.z * 16,
			0xFFFFFFFF)

		p.hit_from_inside = true

		return Util.intersect_ray_all_3d(get_world_3d().direct_space_state, p)


func shoot() -> void:
	var intersection_result = physics_query.get_intersection_results().front()

	if intersection_result is not Dictionary:
		return

	intersection_result = intersection_result as Dictionary

	var o: Object = intersection_result.collider
	var health = Health.get_from(o)

	if is_instance_valid(health):
		health = health as Health
		health.damage(50)

	intersections_detected.emit([ intersection_result ])
