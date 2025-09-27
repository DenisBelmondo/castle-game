@tool
extends Node


@export var root: Node
var holder: Node


func _ready() -> void:
	var new_root = root

	if not is_instance_valid(new_root):
		new_root = owner

	if not is_instance_valid(new_root):
		new_root = get_parent()

	root = new_root
