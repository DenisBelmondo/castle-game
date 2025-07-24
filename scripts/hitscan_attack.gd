@tool
extends Node


const Hit := preload('res://scripts/resources/hit.gd')

@export var distance: float = 16:
	set(value):
		distance = value
		ray_cast_3d.target_position = Vector3.FORWARD * distance

@export var hit: Hit
@onready var ray_cast_3d: RayCast3D = $RayCast3D


func _ready() -> void:
	# trigger setter
	distance = distance

	hit.check_function = func (__: Array) -> Variant:
		return ray_cast_3d.get_collider()
