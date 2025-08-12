extends Node


const Bob := preload('res://scripts/bob.gd')
const CastleGameUtil := preload('res://scripts/castle_game_util.gd')
const CastleGameViewWeapon := preload('res://scripts/view_weapons/castle_game_view_weapon.gd')
const CastleGameMode := preload('castle_game_mode.gd')
const Character := preload('res://scripts/nodes/character.gd')
const CollisionLayers := preload('res://scripts/collision_layers.gd')
const GroupNames := preload('res://scripts/group_names.gd')
const Health := preload('res://scripts/health.gd')
const HUD := preload('res://scripts/ui/hud.gd')
const InteractionEngine := preload('res://scripts/interaction_engine/static.gd')
const Pickup := preload('res://scripts/pickup.gd')
const Player := preload('res://scripts/player.gd')
const PlayerCamera := preload('res://scripts/player.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/remote_interpolated_transformer_3d.gd')
const Util := preload('res://scripts/util.gd')
const ViewWeapon := preload('res://scripts/view_weapons/view_weapon.gd')
const Zombie := preload('res://scripts/zombie.gd')


class CastleGamePlayer:
	var player: Player
	var audio_ui: AudioStreamPlayer3D
	var view_weapon: ViewWeapon
	var camera: Camera3D
	var hud: HUD
	var inventory: Dictionary


const PLAYER_CAMERA_SCENE := preload('res://scenes/nodes/player_camera.tscn')
const PLAYER_INTERACTOR_AREA := preload('res://scenes/nodes/player_interactor_area.tscn')
const PLAYER_HURT_SOUND := preload('res://audio/sounds/player_hurt.wav')
const HUD_SCENE := preload('res://scenes/ui/hud.tscn')
const V_REVOLVER_SCENE := preload('res://scenes/view_weapons/v_revolver.tscn')
const V_SHOTGUN_SCENE := preload('res://scenes/view_weapons/v_shotgun.tscn')
const COURTYARD_SCENE := preload('res://scenes/maps/court_yard.tscn')

static var _instance: CastleGameMode

@export var current_scene: PackedScene

var _weapon_attacks: Dictionary[StringName, Callable] = {
	&'revolver_attack': (func (weapon: ViewWeapon, user_data: Variant) -> void:
			var p := PhysicsRayQueryParameters3D.create(
				weapon.global_position,
				weapon.global_position
						- weapon.global_basis.z
								.rotated(weapon.global_basis.y, randf_range(-PI / 30.0, PI / 30.0))
								.rotated(weapon.global_basis.x, randf_range(-PI / 60.0, PI / 60.0))
								* 32)

			p.hit_from_inside = true

			var results := Util.intersect_ray_all_3d(get_viewport().world_3d.direct_space_state, p)

			results = Util.filter_physics_query_by_object(results, weapon.physics_exclude)

			if results.is_empty():
				return

			var first_result = results.front()
			var collider = first_result.collider

			collider = collider as Node

			var collider_health = CastleGameUtil.get_meta_from(collider, Health)

			if collider_health is Health:
				collider_health.damage(randi_range(1, 3) * 10)

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
						impact_fx.look_at.call_deferred(first_result.position + first_result.normal)),
	# [TODO]: refactor
	&'shotgun_attack': (func (weapon: ViewWeapon, user_data: Variant) -> void:
		for i in 7:
			var p := PhysicsRayQueryParameters3D.create(
				weapon.global_position,
				weapon.global_position
						- weapon.global_basis.z
								.rotated(weapon.global_basis.y, randf_range(-PI / 30.0, PI / 30.0))
								.rotated(weapon.global_basis.x, randf_range(-PI / 60.0, PI / 60.0))
								* 32)

			p.hit_from_inside = true

			var results := Util.intersect_ray_all_3d(get_viewport().world_3d.direct_space_state, p)

			results = Util.filter_physics_query_by_object(results, weapon.physics_exclude)

			if results.is_empty():
				return

			var first_result = results.front()
			var collider = first_result.collider

			collider = collider as Node

			var collider_health = CastleGameUtil.get_meta_from(collider, Health)

			if collider_health is Health:
				collider_health.damage(randi_range(1, 3) * 5)

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
						impact_fx.look_at.call_deferred(first_result.position + first_result.normal)),
}

var _current_scene: Node
var _players: Dictionary[Player, CastleGamePlayer]

@onready var _viewport: SubViewport = %GameViewport


static func get_instance() -> CastleGameMode:
	return _instance


static func _toggle_mouse_mode() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# [TODO]: UGHHHHHHHHHHHH
func _init() -> void:
	_instance = self


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	change_map(current_scene.instantiate())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			_toggle_mouse_mode()

		if event.keycode == KEY_1:
			var p: Player = _players.keys().front()
			var pp: CastleGamePlayer = _players[p]

			if 'revolver' in pp.inventory:
				var w := V_REVOLVER_SCENE.instantiate()

				if is_instance_valid(pp.view_weapon):
					pp.view_weapon.queue_free()

				pp.view_weapon = w
				CastleGameUtil.attach_view_weapon_to_player(w, p)
		elif event.keycode == KEY_2:
			var p: Player = _players.keys().front()
			var pp: CastleGamePlayer = _players[p]

			if 'shotgun' in pp.inventory:
				var w := V_SHOTGUN_SCENE.instantiate()

				if is_instance_valid(pp.view_weapon):
					pp.view_weapon.queue_free()

				pp.view_weapon = w
				CastleGameUtil.attach_view_weapon_to_player(w, p)


func change_map(scene_root: Node, preserve_players: bool = false) -> void:
	if is_instance_valid(_current_scene):
		_current_scene.queue_free()

	if not preserve_players:
		_players.clear()

	Util.reparent_or_add_child.call_deferred(scene_root, _viewport)
	set_deferred(&'_current_scene', scene_root)


func restart_map() -> void:
	var sf := _current_scene.scene_file_path
	_current_scene.queue_free()

	await get_tree().process_frame

	change_map(load(sf).instantiate())


func restart_game() -> void:
	change_map(COURTYARD_SCENE.instantiate())


func _set_up_player(player: Player) -> void:
	player.character.body.collision_layer = CollisionLayers.CHARACTERS
	player.character.body.collision_mask = CollisionLayers.WORLD | CollisionLayers.CHARACTERS | CollisionLayers.ITEMS

	var player_interactor_area := PLAYER_INTERACTOR_AREA.instantiate()
	var camera := PLAYER_CAMERA_SCENE.instantiate()
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
	castle_game_player.set_deferred(&'camera', camera)
	camera.make_current.call_deferred()
	audio_listener.make_current.call_deferred()

	CastleGameUtil.attach_interpolated(audio_listener, player.inner_head)

	# give weapon
	#CastleGameUtil.attach_view_weapon_to_player(shotgun, player)
	#castle_game_player.view_weapon = shotgun

	# bob shit
	for bob: Bob in Util.find_children(player, func (c: Node) -> bool: return c is Bob):
		bob.get_bob_strength_function = func () -> float:
			return (float(player.character.linear_velocity.length_squared() > 0.5)
					* float(player.character.movement_result.was_on_floor
							or player.character.movement_result.is_on_floor))

	player.character.body.collision_layer |= CollisionLayers.SIGHT

	await player.ready

	var player_health: Health = CastleGameUtil.get_meta_from(player.character, Health)

	castle_game_player.hud = HUD_SCENE.instantiate()
	castle_game_player.hud.health = player_health
	player.add_child.call_deferred(castle_game_player.hud)
	player_health.depleted.connect(restart_game)


func _on_node_added(node: Node) -> void:
	if node.is_in_group(GroupNames.ONLY_VISIBLE_IN_EDITOR):
		node.visible = false
		node.queue_free()
		return

	if node is Character:
		node.body.collision_layer = CollisionLayers.CHARACTERS
		node.body.collision_mask = CollisionLayers.WORLD | CollisionLayers.CHARACTERS | CollisionLayers.ITEMS
	elif node is Player:
		_set_up_player(node)
	elif node is Pickup:
		node.area.collision_layer = CollisionLayers.ITEMS
		node.area.collision_mask = CollisionLayers.CHARACTERS

		node.area.body_entered.connect(func (body: Node) -> void:
			var p = _players.get(body.owner)

			if is_instance_valid(p):
				p = p as CastleGamePlayer
				p.inventory[node.hint] = 1
				p.audio_ui.stream = preload('res://audio/sounds/pick_up_weapon.tres')
				p.audio_ui.play()
				node.queue_free())
	elif node is ViewWeapon:
		node.event.connect(func (p_name: StringName, user_data: Variant) -> void:
			var f = _weapon_attacks.get(p_name)

			if f is Callable:
				_weapon_attacks[p_name].call(node, user_data)
			else:
				push_warning('attack "%s" not implemented.' % p_name))
	elif node is Zombie:
		await node.ready

		node.sight_targets = _players.keys().map(func (p: Player) -> Node3D: return p.character.body)
		node.hitbox.collision_layer = 0
		node.hitbox.collision_mask = CollisionLayers.CHARACTERS

		node.poop.connect(func (thing: Node3D) -> void:
			if thing.owner is Player and thing.owner in _players:
				var p := thing.owner as Player
				var player: CastleGamePlayer = _players[p]

				#p.character.linear_velocity += node.character.global_position.direction_to(p.character.global_position)

				var health = CastleGameUtil.get_meta_from(p.character, Health)

				if health is Health:
					health.damage(25)

				player.audio_ui.stream = PLAYER_HURT_SOUND
				player.audio_ui.play()
				player.camera.shake())
