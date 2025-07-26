#
# a bunch of static functions with special knowledge of types and playsim.
#
# all functions in here should be static and should be consumed by a "game mode"
# object that implements some kind of a game with them. this class should not
# be instantiated.
#

const Health := preload('res://scripts/health.gd')
const PhysicsQuery := preload('res://scripts/physics_query.gd')
const Player := preload('res://scripts/player.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/remote_interpolated_transformer_3d.gd')
const Util := preload('res://scripts/util.gd')
const ViewWeapon := preload('res://scripts/view_weapon.gd')


static func attach_camera(camera: Camera3D, to: Node3D) -> void:
	var head_to_camera_rt := RemoteInterpolatedTransformer.new()

	head_to_camera_rt.target_physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	Util.reparent_or_add_child.call_deferred(head_to_camera_rt, to)
	Util.reparent_or_add_child.call_deferred(camera, to)
	head_to_camera_rt.set_deferred(&'source', to)
	head_to_camera_rt.set_target.call_deferred(camera)


static func give_weapon_to_player(weapon: ViewWeapon, player: Player) -> void:
	var weapon_to_camera_rt := RemoteInterpolatedTransformer.new()

	weapon_to_camera_rt.target_physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	weapon_to_camera_rt.source = player.inner_head
	weapon_to_camera_rt.set_target(weapon.root)
	player.inner_head.add_child.call_deferred(weapon_to_camera_rt)
	Util.reparent_or_add_child.call_deferred(weapon.root, player.inner_head)

	if not weapon.is_node_ready():
		await weapon.ready

	var physics_queries: Array[PhysicsQuery]
	var exclude: Array[Object] = [ player.character.body ]

	# [TODO]: buhhhhh
	physics_queries.assign(Util.find_children(weapon.root, func (c: Node) -> bool: return c is PhysicsQuery, true, false))

	for pq in physics_queries:
		pq.exclude = exclude
