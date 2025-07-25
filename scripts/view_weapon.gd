extends Node


signal primary_attack_event


var holder: Node


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&'attack_primary'):
		primary_attack_event.emit()
