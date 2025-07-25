extends Node3D


const CastleGame := preload('res://scripts/castle_game.gd')
const Health := preload('res://scripts/health.gd')
const PhysicsQuery := preload('res://scripts/physics_query.gd')
const Util := preload('res://scripts/util.gd')

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
	for d in physics_query.get_intersection_results():
		var o: Object = d.collider
		var health = Health.get_from(o)

		if is_instance_valid(health):
			health = health as Health
			health.damage(50)
