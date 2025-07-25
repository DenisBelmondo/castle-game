extends Node3D


@export var exclude: Dictionary
var get_overlappers_function: Callable


func get_overlappers() -> Array[Object]:
	return get_overlappers_function.call()
