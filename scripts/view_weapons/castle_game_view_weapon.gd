extends Node


const ViewWeapon := preload('res://scripts/view_weapon.gd')

@export var view_weapon: ViewWeapon
@export var animation_player: AnimationPlayer
@export var bob_animation_tree: AnimationTree
@export var attack_primary_animation_name: StringName = &'attack_primary'


func _ready() -> void:
	view_weapon.primary_attack_event.connect(attack_primary)


func attack_primary() -> void:
	animation_player.play(attack_primary_animation_name)
