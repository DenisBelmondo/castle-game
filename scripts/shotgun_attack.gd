extends Node3D


const PhysicsQuery := preload('res://scripts/physics_query.gd')

@onready var physics_query: PhysicsQuery = $PhysicsQuery


func _ready() -> void:
	physics_query.get_overlappers_function = func () -> Array[Object]:
		var results: Array[Object] = []
		var p := PhysicsRayQueryParameters3D.create(
			global_position,
			global_basis.z * 16,
			0xFFFFFFFF,
			physics_query.exclude.keys())

		get_world_3d().direct_space_state.intersect_ray(p)

		return results


func shoot() -> void:
	for o in physics_query.get_overlappers():
		print(o)
