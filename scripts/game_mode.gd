extends Node


const CastleGameUtil := preload('res://scripts/castle_game_util.gd')
const CastleGameViewWeapon := preload('res://scripts/view_weapons/castle_game_view_weapon.gd')
const GameMode := preload('game_mode.gd')
const GroupNames := preload('res://scripts/group_names.gd')
const Health := preload('res://scripts/health.gd')
const InteractionEngine := preload('res://scripts/interaction_engine/static.gd')
const LocalGameContext := preload('res://scripts/local_game_context.gd')
const Player := preload('res://scripts/player.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/remote_interpolated_transformer_3d.gd')
const ShotgunAttack := preload('res://scripts/shotgun_attack.gd')
const Util := preload('res://scripts/util.gd')
const ViewWeapon := preload('res://scripts/view_weapon.gd')

const PLAYER_INTERACTOR_AREA := preload('res://scenes/nodes/player_interactor_area.tscn')
const V_SHOTGUN_SCENE := preload('res://scenes/view_weapons/v_shotgun.tscn')

@export var current_scene: PackedScene
var _current_scene: Node
@onready var _viewport: SubViewport = %GameViewport


static func _toggle_mouse_mode() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func _set_up_player(player: Player) -> void:
	var player_interactor_area := PLAYER_INTERACTOR_AREA.instantiate()
	var camera := Camera3D.new()
	var shotgun := V_SHOTGUN_SCENE.instantiate()

	# intentional assignment instead of OR'ing
	player_interactor_area.collision_mask = InteractionEngine.LAYER_MASK
	player.inner_head.add_child.call_deferred(player_interactor_area)

	CastleGameUtil.attach_camera.call_deferred(camera, player.inner_head)
	camera.make_current.call_deferred()

	CastleGameUtil.give_weapon_to_player.call_deferred(shotgun.view_weapon, player)
	shotgun.set_deferred(&'get_bob_strength_function', func () -> float: return player.movement_axes.length_squared())


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


func _on_node_added(node: Node) -> void:
	if node.is_in_group(GroupNames.ONLY_VISIBLE_IN_EDITOR):
		node.visible = false
		node.queue_free()
		return

	if node is Player:
		_set_up_player(node)
	elif node is LocalGameContext:
		node.current_scene_root = _current_scene

	#get_tree().physics_frame.connect(func () -> void:
		#node.bob_animation_tree[&'parameters/blend_position'] = player.movement_axes.length_squared())
