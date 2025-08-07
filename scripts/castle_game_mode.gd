extends Node


const CastleGameUtil := preload('res://scripts/castle_game_util.gd')
const CastleGameViewWeapon := preload('res://scripts/view_weapons/castle_game_view_weapon.gd')
const CastleGameMode := preload('castle_game_mode.gd')
const GroupNames := preload('res://scripts/group_names.gd')
const Health := preload('res://scripts/health.gd')
const InteractionEngine := preload('res://scripts/interaction_engine/static.gd')
const Pickup := preload('res://scripts/pickup.gd')
const Player := preload('res://scripts/player.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/remote_interpolated_transformer_3d.gd')
const Util := preload('res://scripts/util.gd')
const ViewWeapon := preload('res://scripts/view_weapons/view_weapon.gd')


class CastleGamePlayer:
	var player: Player
	var audio_ui: AudioStreamPlayer3D


const PLAYER_INTERACTOR_AREA := preload('res://scenes/nodes/player_interactor_area.tscn')
const V_REVOLVER_SCENE := preload('res://scenes/view_weapons/v_revolver.tscn')
const V_SHOTGUN_SCENE := preload('res://scenes/view_weapons/v_shotgun.tscn')

@export var current_scene: PackedScene

var _weapon_attacks: Dictionary[StringName, Callable] = {
	# [TODO]: refactor
	&'shotgun_attack': func (weapon: ViewWeapon, user_data: Variant) -> void:
		for i in 7:
			var p := PhysicsRayQueryParameters3D.create(
				weapon.global_position,
				weapon.global_position
						- weapon.global_basis.z
								.rotated(weapon.global_basis.y, randf_range(-PI / 30.0, PI / 30.0))
								.rotated(weapon.global_basis.x, randf_range(-PI / 60.0, PI / 60.0))
								* 16)

			p.hit_from_inside = true

			var results := Util.intersect_ray_all_3d(get_viewport().world_3d.direct_space_state, p)

			results = Util.filter_physics_query_by_object(results, weapon.physics_exclude)

			var first_result = results.front()
			var collider = first_result.collider

			if collider is not Node:
				return

			collider = collider as Node

			var collider_owner = collider.owner

			if collider_owner is not Node:
				return

			collider_owner = collider_owner as Node

			var impact_fx_scene := CastleGameUtil.get_impact_effect_for_node(collider_owner)

			if impact_fx_scene is PackedScene:
				var impact_fx := impact_fx_scene.instantiate()

				_current_scene.add_child.call_deferred(impact_fx)

				var position = first_result.get(&'position')
				var normal = first_result.get(&'normal')

				if position is Vector3:
					impact_fx.set_deferred(&'global_position', first_result.position)
					impact_fx.set_deferred(&'emitting', true)

					if normal is Vector3:
						impact_fx.set_deferred(&'global_position', first_result.position + first_result.normal / 10.0)
						impact_fx.look_at.call_deferred(first_result.position + first_result.normal)
}

var _current_scene: Node
var _players: Dictionary

@onready var _viewport: SubViewport = %GameViewport


static func _toggle_mouse_mode() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	change_map(current_scene.instantiate())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			_toggle_mouse_mode()


func change_map(scene_root: Node) -> void:
	if is_instance_valid(_current_scene):
		_current_scene.queue_free()

	Util.reparent_or_add_child.call_deferred(scene_root, _viewport)
	set_deferred(&'_current_scene', scene_root)


func _set_up_player(player: Player) -> void:
	var player_interactor_area := PLAYER_INTERACTOR_AREA.instantiate()
	var camera := Camera3D.new()
	var audio_listener := AudioListener3D.new()
	var shotgun := V_SHOTGUN_SCENE.instantiate()

	var castle_game_player := CastleGamePlayer.new()

	castle_game_player.audio_ui = AudioStreamPlayer3D.new()
	_players[player] = castle_game_player
	camera.add_child.call_deferred(castle_game_player.audio_ui)

	# intentional assignment instead of OR'ing
	player_interactor_area.collision_mask = InteractionEngine.LAYER_MASK
	player.inner_head.add_child.call_deferred(player_interactor_area)

	player.inner_head.add_child.call_deferred(camera)
	camera.make_current.call_deferred()
	audio_listener.make_current.call_deferred()

	CastleGameUtil.attach_interpolated(audio_listener, player.inner_head)
	CastleGameUtil.attach_view_weapon_to_player(shotgun, player)


func _on_node_added(node: Node) -> void:
	if node.is_in_group(GroupNames.ONLY_VISIBLE_IN_EDITOR):
		node.visible = false
		node.queue_free()
		return

	if node is Player:
		_set_up_player(node)
	elif node is Pickup:
		node.area.body_entered.connect(func (body: Node) -> void:
			var p = _players.get(body.owner)

			if is_instance_valid(p):
				p = p as CastleGamePlayer
				p.audio_ui.stream = preload('res://audio/sounds/pick_up_weapon.tres')
				p.audio_ui.play()
				node.queue_free())
	elif node is ViewWeapon:
		node.event.connect(func (p_name: StringName, user_data: Variant) -> void:
			var f = _weapon_attacks.get(p_name)

			if f is Callable:
				_weapon_attacks[p_name].call(node, user_data)
			else:
				push_warning('attack "%s" not found in weapon attacks!' % p_name))
