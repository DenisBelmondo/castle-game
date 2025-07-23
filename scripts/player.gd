extends CharacterBody3D


class CharacterMovement:
	var is_on_floor: bool
	var was_on_floor: bool
	var lateral_velocity: Vector3
	var vertical_velocity: Vector3

	static func normal_is_floor(normal: Vector3, up: Vector3, max_floor_angle: float) -> bool:
		return acos(normal.dot(up)) < max_floor_angle + 0.01

	static func _collision_has_floor(collision: KinematicCollision3D, up: Vector3, max_floor_angle: float) -> bool:
		for i in collision.get_collision_count():
			var n := collision.get_normal(i)

			if normal_is_floor(n, up, max_floor_angle):
				return true

		return false

	func character_move_floor(body: CharacterBody3D, relative_motion: Vector3, step_height: float, max_floor_angle: float, on_step_function: Callable = Callable(), on_land_function: Callable = Callable()) -> void:
		var old_position := body.global_position

		lateral_velocity = relative_motion.slide(body.global_basis.y)
		vertical_velocity = relative_motion.project(body.global_basis.y)

		was_on_floor = is_on_floor
		is_on_floor = false

		#
		# move up, forward, then down
		#

		var step_up_col := body.move_and_collide(body.global_basis.y * step_height)

		var old_velocity := body.velocity

		body.velocity = lateral_velocity
		body.move_and_slide()
		is_on_floor = is_on_floor or body.is_on_floor()

		var lateral_velocity_after_stepping := body.get_real_velocity()

		body.velocity = old_velocity

		var step_down_vec := -body.global_basis.y * step_height

		if is_instance_valid(step_up_col):
			step_down_vec = -step_up_col.get_travel()

		var step_down_col := body.move_and_collide(step_down_vec)
		var position_after_stepping := body.global_position

		if is_instance_valid(step_down_col):
			var collision_has_floor := _collision_has_floor(step_down_col, body.global_basis.y, max_floor_angle)

			is_on_floor = is_on_floor or collision_has_floor

			if collision_has_floor:
				if on_step_function.is_valid():
					on_step_function.call(position_after_stepping, old_position)

		# undo the move
		body.global_position = old_position

		#
		# try moving normally
		#

		old_velocity = body.velocity
		body.velocity = lateral_velocity
		body.move_and_slide()
		is_on_floor = is_on_floor or body.is_on_floor()

		var lateral_velocity_after_moving_normally := body.get_real_velocity()

		body.velocity = old_velocity

		var position_after_moving_normally := body.global_position

		body.global_position = old_position

		#
		# take whichever move went furthest
		#

		var new_position := position_after_moving_normally

		lateral_velocity = lateral_velocity_after_moving_normally

		if old_position.distance_squared_to(position_after_stepping) > old_position.distance_squared_to(position_after_moving_normally):
			new_position = position_after_stepping
			lateral_velocity = lateral_velocity_after_stepping

		body.global_position = new_position

		#
		# vertical velocity
		#

		var vertical_velocity_before_flying := vertical_velocity

		old_velocity = body.velocity
		body.velocity = vertical_velocity
		body.move_and_slide()
		vertical_velocity = body.get_real_velocity()
		body.velocity = old_velocity
		is_on_floor = is_on_floor or body.is_on_floor()

		#
		# snapping
		#

		var should_snap := not is_on_floor and was_on_floor

		should_snap = should_snap and not vertical_velocity.dot(body.global_basis.y) > 0

		if should_snap:
			var snap_col := body.move_and_collide(-body.global_basis.y * step_height, true)

			if is_instance_valid(snap_col) and _collision_has_floor(snap_col, body.global_basis.y, max_floor_angle):
				body.global_position += snap_col.get_travel()

				if on_step_function.is_valid():
					on_step_function.call(body.global_position, old_position)

		if not was_on_floor and is_on_floor and vertical_velocity_before_flying.dot(body.global_basis.y) < 0:
			if on_land_function.is_valid():
				on_land_function.call(vertical_velocity_before_flying)


signal jumped
signal landed_hard(force: Vector3)
signal stepped(new_position: Vector3, old_position: Vector3)

@export_category('References')
@export var body: CharacterBody3D
@export var outer_head: Node3D
@export var inner_head: Node3D

@export_category('Properties')
@export var walk_speed: float = 1
@export var deceleration_rate: float = 1.0 / 3.0
@export var vertical_look_clamp: Vector2 = Vector2(-90, 90)
@export var jump_force: float = 8
@export var fall_rate: float = 0.75
@export var max_fall_rate: float = 20
@export var step_height: float = 0.375
@export var hard_landing_threshold: float = 4

var _forward_movement_axis: float
var _strafe_movement_axis: float
var _movement_state: CharacterMovement = CharacterMovement.new()
var gravity: Vector3
var walk_velocity: Vector3


func _process(delta: float) -> void:
	body.floor_snap_length = 0
	_forward_movement_axis = Input.get_axis(&'move_backwards', &'move_forward')
	_strafe_movement_axis = Input.get_axis(&'move_left', &'move_right')


# [TODO]: refactor!

func _physics_process(_delta: float) -> void:
	var forward_move := Input.get_axis(&'move_backwards', &'move_forward')
	var strafe_move := Input.get_axis(&'move_left', &'move_right')
	var walk_vector := -outer_head.basis.z * forward_move

	walk_vector += outer_head.basis.x * strafe_move
	walk_vector = walk_vector.normalized()
	walk_vector *= walk_speed
	walk_vector *= float(_movement_state.is_on_floor)
	walk_velocity += walk_vector

	gravity -= body.global_basis.y * fall_rate

	if gravity.dot(body.global_basis.y) < -max_fall_rate:
		gravity = -body.global_basis.y * max_fall_rate

	var final_movement_vector := walk_velocity + gravity

	_movement_state.character_move_floor(body, final_movement_vector, step_height, body.floor_max_angle, stepped.emit, func (force: Vector3) -> void:
		if force.length_squared() > pow(max_fall_rate / 2, 2) / 3:
			landed_hard.emit(force))

	walk_velocity = _movement_state.lateral_velocity
	gravity = _movement_state.vertical_velocity

	#
	# deceleration
	#

	if _movement_state.is_on_floor:
		walk_velocity = walk_velocity.lerp(Vector3.ZERO, deceleration_rate)


func _unhandled_input(event: InputEvent) -> void:
	basic_player_look(event, outer_head, inner_head, vertical_look_clamp)

	#if event.is_action_pressed(&'jump'):
		#await get_tree().physics_frame
#
		#if _movement_state.is_on_floor:
			#gravity += global_basis.y


static func basic_player_look(event: InputEvent, outer_head: Node3D, inner_head: Node3D, vertical_look_clamp: Vector2 = Vector2(-90, 90)) -> void:
	if event is InputEventMouseMotion:
		event.screen_relative *= float(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
		event.screen_relative /= 500
		outer_head.rotation.y -= event.screen_relative.x
		inner_head.rotation.x -= event.screen_relative.y
		inner_head.rotation_degrees.x = clampf(inner_head.rotation_degrees.x, vertical_look_clamp.x, vertical_look_clamp.y)
