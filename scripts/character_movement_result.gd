extends Object


enum SurfaceType {
	WALL = 0,
	FLOOR = 1 << 0,
	CEILING = 1 << 1,
}


# stateful vars after calling the "move" family of functions
var is_on_floor: bool
var is_on_ceiling: bool
var was_on_floor: bool
var was_on_ceiling: bool
var lateral_velocity: Vector3
var vertical_velocity: Vector3
var linear_velocity: Vector3


static func normal_is_floor(normal: Vector3, up: Vector3, max_floor_angle: float) -> bool:
	return acos(normal.dot(up)) <= max_floor_angle + 0.01


static func normal_is_ceiling(normal: Vector3, up: Vector3, max_ceiling_angle: float) -> bool:
	return acos(normal.dot(-up) <= max_ceiling_angle + 0.01)


static func _get_collision_surface_types(collision: KinematicCollision3D, up: Vector3, max_floor_angle: float, max_ceiling_angle: float) -> SurfaceType:
	var st := SurfaceType.WALL

	for i in collision.get_collision_count():
		var n := collision.get_normal(i)

		@warning_ignore('int_as_enum_without_cast')
		st |= int(normal_is_floor(n, up, max_floor_angle)) * SurfaceType.FLOOR

		@warning_ignore('int_as_enum_without_cast')
		st |= int(normal_is_ceiling(n, up, max_ceiling_angle)) * SurfaceType.CEILING

	return st


func character_move(body: CharacterBody3D, relative_motion: Vector3) -> void:
	was_on_floor = is_on_floor
	was_on_ceiling = is_on_ceiling
	is_on_floor = false
	is_on_ceiling = false
	body.velocity = relative_motion
	body.move_and_slide()
	is_on_floor = is_on_floor or body.is_on_floor()
	is_on_ceiling = is_on_ceiling or body.is_on_ceiling()
	linear_velocity = body.get_real_velocity()


func character_move_and_step(body: CharacterBody3D, relative_motion: Vector3, step_height: float, max_floor_angle: float, max_ceiling_angle: float, on_step_function: Callable = Callable(), on_land_function: Callable = Callable()) -> void:
	var old_position := body.global_position

	lateral_velocity = relative_motion.slide(body.global_basis.y)
	vertical_velocity = relative_motion.project(body.global_basis.y)

	was_on_floor = is_on_floor
	was_on_ceiling = is_on_ceiling
	is_on_floor = false
	is_on_ceiling = false

	#
	# move up, forward, then down
	#

	var step_up_col := body.move_and_collide(body.global_basis.y * step_height)

	var old_velocity := body.velocity

	body.velocity = lateral_velocity
	body.move_and_slide()
	is_on_floor = is_on_floor or body.is_on_floor()
	is_on_ceiling = is_on_ceiling or body.is_on_ceiling()

	var lateral_velocity_after_stepping := body.get_real_velocity()

	body.velocity = old_velocity

	var step_down_vec := -body.global_basis.y * step_height

	if is_instance_valid(step_up_col):
		step_down_vec = -step_up_col.get_travel()

	var step_down_col := body.move_and_collide(step_down_vec)
	var position_after_stepping := body.global_position

	if is_instance_valid(step_down_col):
		var collision_surfaces := _get_collision_surface_types(step_down_col, body.global_basis.y, max_floor_angle, max_ceiling_angle)
		var collision_has_floor := collision_surfaces & SurfaceType.FLOOR
		var collision_has_ceiling := collision_surfaces & SurfaceType.CEILING

		is_on_floor = is_on_floor or collision_has_floor
		collision_has_ceiling = collision_has_ceiling or collision_has_ceiling

		if collision_has_floor:
			if on_step_function.is_valid():
				on_step_function.call(position_after_stepping, old_position)

	# undo the move
	body.global_position = old_position

	#
	# try moving normally
	#

	old_velocity = body.velocity
	_regular_character_move(body, lateral_velocity)
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
	is_on_ceiling = is_on_ceiling or body.is_on_ceiling()

	#
	# snapping
	#

	var should_snap := not is_on_floor and was_on_floor

	should_snap = should_snap and not vertical_velocity.dot(body.global_basis.y) > 0

	if should_snap:
		var snap_col := body.move_and_collide(-body.global_basis.y * step_height, true)

		if is_instance_valid(snap_col) and (_get_collision_surface_types(snap_col, body.global_basis.y, max_floor_angle, max_ceiling_angle) & SurfaceType.FLOOR):
			body.global_position += snap_col.get_travel()

			if on_step_function.is_valid():
				on_step_function.call(body.global_position, old_position)

	if not was_on_floor and is_on_floor and vertical_velocity_before_flying.dot(body.global_basis.y) < 0:
		if on_land_function.is_valid():
			on_land_function.call(vertical_velocity_before_flying)

	linear_velocity = lateral_velocity + vertical_velocity


func _regular_character_move(body: CharacterBody3D, relative_motion: Vector3) -> void:
	body.velocity = relative_motion
	body.move_and_slide()
	is_on_floor = is_on_floor or body.is_on_floor()
	is_on_ceiling = is_on_ceiling or body.is_on_ceiling()
