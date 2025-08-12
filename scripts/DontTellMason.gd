extends Node

@export var tracking_zombie : Node3D
@export var event_anim : AnimationPlayer


func _ready() -> void:
	tracking_zombie.died.connect(dead)
	
func dead():
	event_anim.play("Event")
