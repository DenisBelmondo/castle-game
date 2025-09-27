extends Node3D


@export var bob_animation_tree: AnimationTree
var get_bob_strength_function: Callable


func _physics_process(_delta: float) -> void:
	if get_bob_strength_function.is_valid():
		bob_animation_tree[&'parameters/blend_position'] = get_bob_strength_function.call()
