#
# a bunch of static functions with special knowledge of types and playsim.
#
# all functions in here should be static and should be consumed by a "game mode"
# object that implements some kind of a game with them. this class should not
# be instantiated.
#

const CastleGameViewWeapon := preload('res://scripts/view_weapons/castle_game_view_weapon.gd')
const Health := preload('res://scripts/health.gd')
const Player := preload('res://scripts/player.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/remote_interpolated_transformer_3d.gd')
const Sandbag := preload('res://scripts/characters/sandbag.gd')
const Util := preload('res://scripts/util.gd')
const ViewWeapon := preload('res://scripts/view_weapons/view_weapon.gd')
const Zombie := preload('res://scripts/zombie.gd')

const FX_BLOOD := preload('res://scenes/effects/blood_spurt.tscn')
const FX_PUFF := preload('res://scenes/effects/spark_puff.tscn')


static func attach_interpolated(child: Node3D, parent: Node3D) -> void:
	var rt := RemoteInterpolatedTransformer.new()

	rt.target_physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	Util.reparent_or_add_child(rt, parent)
	Util.reparent_or_add_child(child, parent)
	rt.set_deferred(&'source', parent)
	rt.set_target.call_deferred(child)


static func attach_camera(camera: Camera3D, to: Node3D) -> void:
	attach_interpolated(camera, to)


static func attach_view_weapon_to_player(view_weapon: ViewWeapon, player: Player) -> void:
	if not player.is_node_ready():
		await player.ready

	view_weapon.physics_exclude.assign(player.find_children('*', 'CollisionObject3D', true, false))

	# [TODO]: loll?
	if view_weapon is CastleGameViewWeapon:
		view_weapon.get_bob_strength_function = (func () -> float:
				return (
					player.character.linear_velocity.slide(player.character.global_basis.y).length_squared()
							* float(player.character.movement_result.is_on_floor)))

	attach_interpolated(view_weapon, player.inner_head)
	view_weapon.set_deferred(&'owner', player)


static func get_impact_effect_for_node(node: Node) -> PackedScene:
	if node is Sandbag or node is Zombie:
		return FX_BLOOD

	return FX_PUFF


static func get_meta_dict_from(object: Object) -> Variant:
	if object.has_meta(&'castle_game_'):
		return object.get_meta(&'castle_game_')

	return null


## Gets metadata from object with unified game-specific prefix.
static func get_meta_from(object: Object, key: Variant) -> Variant:
	var d = get_meta_dict_from(object)

	if d is Dictionary:
		return d.get(key)

	return null


## Sets metadata to object with unified game-specific prefix.
static func set_meta_on(object: Object, key: Variant, value: Variant) -> void:
	var d: Dictionary

	if object.has_meta(&'castle_game_'):
		d = object.get_meta(&'castle_game_', {})

	object.set_meta(&'castle_game_', d)
	d.set(key, value)


static func remove_meta_from(object: Object, key: Variant) -> void:
	var d = get_meta_dict_from(object)

	if not d:
		return

	d = d as Dictionary
	d.erase(key)
