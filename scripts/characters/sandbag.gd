extends Node3D


const Health := preload('res://scripts/health.gd')

@export var health: Health


func _ready() -> void:
	health.damaged.connect(func (__, ___) -> void:
		if health.amount <= 0:
			queue_free())
