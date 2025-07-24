extends Node3D


const ViewWeapon := preload('res://scripts/view_weapon.gd')


@export var view_weapon: ViewWeapon
@export var animation_player: AnimationPlayer
@export var bob_animation_tree: AnimationTree


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&'attack_primary'):
		animation_player.play(&'shoot')
