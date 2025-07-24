#
# a bunch of static functions with special knowledge of types and playsim.
#
# all functions in here should be static and should be consumed by a "game mode"
# object that implements some kind of a game with them. this class should not
# be instantiated.
#

const Player := preload('res://scripts/player.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/remote_interpolated_transformer_3d.gd')
const Util := preload('res://scripts/util.gd')
const ViewWeapon := preload('res://scripts/view_weapon.gd')


static func attach_camera(camera: Camera3D, to: Node3D) -> void:
	var head_to_camera_rt := RemoteInterpolatedTransformer.new()

	head_to_camera_rt.target_physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	Util.reparent_or_add_child(head_to_camera_rt, to)
	Util.reparent_or_add_child(camera, to)
	head_to_camera_rt.set_target.call_deferred(camera)


static func give_weapon_to_player(weapon: ViewWeapon, player: Player) -> void:
	var weapon_to_camera_rt := RemoteInterpolatedTransformer.new()

	weapon_to_camera_rt.target_physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	weapon_to_camera_rt.set_target.call_deferred(weapon.owner)
	player.inner_head.add_child.call_deferred(weapon_to_camera_rt)
	Util.reparent_or_add_child(weapon.owner, player.inner_head)
