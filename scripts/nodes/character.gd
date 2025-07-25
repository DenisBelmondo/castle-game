@tool
extends Node3D


enum AutoIntegrationMode {
	NONE = 0,
	LINEAR_VELOCITY = 1 << 0,
	FREE_FALL_VELOCITY = 1 << 1,
	ALL = LINEAR_VELOCITY | FREE_FALL_VELOCITY,
}


const CharacterMovementResult := preload('res://scripts/character_movement_result.gd')

@export_category('References')
@export var body: CharacterBody3D

@export_category('Properties')

@export_flags('Linear Velocity', 'Free Fall Velocity')
var auto_integration_mode: int = AutoIntegrationMode.ALL

@export var automatically_steps_on_floor: bool = true
@export var step_height: float = 0.375
@export var gravitational_acceleration: float = 0.75
@export var terminal_velocity_length_squared: float = 20 * 20
@export var default_wall_friction: float = 0.0
@export var default_floor_friction: float = 1.0 / 3.0
@export var default_ceiling_friction: float = 0.0

var _movement_state: Variant
var linear_velocity: Vector3
var free_fall_velocity: Vector3

var movement_result: CharacterMovementResult:
	get: return _movement_state


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name': '_movement_state',
			'type': TYPE_OBJECT,
			'usage': PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
			'hint': PROPERTY_HINT_NODE_TYPE,
		}
	]


# [TODO]: ceiling crap
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var final_velocity := Vector3.ZERO

	if auto_integration_mode & AutoIntegrationMode.LINEAR_VELOCITY:
		final_velocity += linear_velocity

	if auto_integration_mode & AutoIntegrationMode.FREE_FALL_VELOCITY:
		free_fall_velocity = -body.global_basis.y * gravitational_acceleration
		final_velocity += free_fall_velocity

	movement_result.character_move_and_step(body, final_velocity, step_height, body.floor_max_angle)
	linear_velocity = movement_result.linear_velocity

	if not is_equal_approx(free_fall_velocity.length_squared(), 0):
		free_fall_velocity = linear_velocity.project(free_fall_velocity.normalized())

	if movement_result.is_on_floor:
		linear_velocity = linear_velocity.lerp(Vector3.ZERO, default_floor_friction)
