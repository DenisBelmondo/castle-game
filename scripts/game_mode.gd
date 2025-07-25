extends Node


const CastleGameUtil := preload('res://scripts/castle_game_util.gd')
const GameMode := preload('game_mode.gd')
const GroupNames := preload('res://scripts/group_names.gd')
const Health := preload('res://scripts/health.gd')
const Player := preload('res://scripts/player.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/remote_interpolated_transformer_3d.gd')
const ShotgunAttack := preload('res://scripts/shotgun_attack.gd')
const Util := preload('res://scripts/util.gd')
const ViewWeapon := preload('res://scripts/view_weapon.gd')

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
	var camera := Camera3D.new()
	var shotgun := V_SHOTGUN_SCENE.instantiate()

	CastleGameUtil.attach_camera.call_deferred(camera, player.inner_head)
	camera.make_current.call_deferred()
	player.get_tree().physics_frame.connect(func () -> void:
		shotgun.bob_animation_tree[&'parameters/blend_position'] = player.movement_axes.length_squared())
	CastleGameUtil.give_weapon_to_player(shotgun.view_weapon, player)


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

	Util.reparent_or_add_child(scene_root, _viewport)
	set.call_deferred(&'_current_scene', scene_root)


func _on_node_added(node: Node) -> void:
	if node.is_in_group(GroupNames.ONLY_VISIBLE_IN_EDITOR):
		node.visible = false
		node.queue_free()
		return

	var object: Object = node

	if object is Player:
		_set_up_player(node)
	elif object is ShotgunAttack:
		object.intersections_detected.connect(_on_attack_intersections_detected)


func _on_attack_intersections_detected(intersections: Array) -> void:
	for i in intersections:
		var puff: Node3D = preload('res://scenes/effects/spark_puff.tscn').instantiate()

		if &'position' in i:
			_current_scene.add_child.call_deferred(puff)
			puff.set.call_deferred(&'global_position', i.position)
			puff.set.call_deferred(&'emitting', true)

			if &'normal' in i:
				puff.look_at.call_deferred(i.position + i.normal)
