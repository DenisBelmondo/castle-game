@tool
extends Node3D


@export var _target: Node3D

var _local_transform: Transform3D


func _ready() -> void:
	set_notify_transform(true)
	_try_readjust_target()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
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

	_target.global_transform = _local_transform * target_parent.get_global_transform_interpolated()
