extends Node


const Character := preload('res://scripts/nodes/character.gd')

signal jumped

@export_category('References')
@export var character: Character
@export var outer_head: Node3D
@export var inner_head: Node3D

@export_category('Properties')
@export var walk_speed: float = 1
@export var vertical_look_clamp: Vector2 = Vector2(-90, 90)
@export var jump_force: float = 8
@export var hard_landing_threshold: float = 4

var movement_axes: Vector2


func _process(_delta: float) -> void:
	movement_axes.y = Input.get_axis(&'move_backwards', &'move_forward')
	movement_axes.x = Input.get_axis(&'move_left', &'move_right')


func _physics_process(_delta: float) -> void:
	var forward_move := Input.get_axis(&'move_backwards', &'move_forward')
	var strafe_move := Input.get_axis(&'move_left', &'move_right')
	var walk_vector := -outer_head.basis.z * forward_move

	walk_vector += outer_head.basis.x * strafe_move
	walk_vector = walk_vector.normalized()
	walk_vector *= walk_speed
	walk_vector *= float(character.movement_result.is_on_floor)
	character.linear_velocity += walk_vector


func _unhandled_input(event: InputEvent) -> void:
	basic_player_look(event, outer_head, inner_head, vertical_look_clamp)

	if event.is_action_pressed(&'jump'):
		await get_tree().physics_frame

		if character.movement_result.is_on_floor:
			character.linear_velocity += character.body.global_basis.y * jump_force


static func basic_player_look(event: InputEvent, p_outer_head: Node3D, p_inner_head: Node3D, p_vertical_look_clamp: Vector2 = Vector2(-90, 90)) -> void:
	if event is InputEventMouseMotion:
		event.screen_relative *= float(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
		event.screen_relative /= 500
		p_outer_head.rotation.y -= event.screen_relative.x
		p_inner_head.rotation.x -= event.screen_relative.y
		p_inner_head.rotation_degrees.x = clampf(p_inner_head.rotation_degrees.x, p_vertical_look_clamp.x, p_vertical_look_clamp.y)
