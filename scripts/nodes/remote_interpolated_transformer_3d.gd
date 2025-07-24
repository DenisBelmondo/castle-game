@tool
extends Node


const DEFAULT_PROCESS_PRIORITY := 999

@export var _target: Node3D
@export var target_physics_interpolation_mode: PhysicsInterpolationMode

var _local_transform: Transform3D


func _init() -> void:
	process_priority = DEFAULT_PROCESS_PRIORITY


func _process(_delta: float) -> void:
	_try_readjust_target()


func get_target() -> Node3D:
	return _target


func set_target(target: Node3D) -> void:
	_target = target
	_target.top_level = true


func _try_readjust_target() -> void:
	if not is_instance_valid(_target):
		return

	var target_parent: Node3D = _target.get_parent()

	if not is_instance_valid(target_parent):
		return

	_target.physics_interpolation_mode = target_physics_interpolation_mode
	_target.global_transform = _local_transform * target_parent.get_global_transform_interpolated()
