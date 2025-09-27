@tool
extends ViewWeapon


const ViewWeapon := preload('res://scripts/view_weapons/view_weapon.gd')

@export var animation_player: AnimationPlayer
@export var bob_animation_tree: AnimationTree
@export var attack_primary_animation_name: StringName = &'attack_primary'
@export var can_shoot_again: bool
@export var ammo_inventory_name_hint: StringName = &''
@export var ammo_use_amount: int = 1

var get_bob_strength_function: Callable
var can_shoot: bool = true


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if get_bob_strength_function.is_valid():
			bob_animation_tree[&'parameters/blend_position'] = get_bob_strength_function.call()


func _unhandled_input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		if event.is_action_pressed(&'attack_primary') and can_shoot:
			attack_primary()


func attack_primary() -> void:
	if can_shoot_again:
		animation_player.stop()
		animation_player.play(attack_primary_animation_name)
