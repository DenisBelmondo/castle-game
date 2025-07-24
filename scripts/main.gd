extends Node


const GroupNames := preload('res://scripts/group_names.gd')
const Player := preload('res://scripts/player.gd')
const ViewWeapon := preload('res://scripts/view_weapon.gd')
const RemoteInterpolatedTransformer := preload('res://scripts/nodes/remote_interpolated_transformer_3d.gd')
const V_SHOTGUN_SCENE := preload('res://scenes/view_sprites/v_shotgun.tscn')


class PlayerInfo:
	var player: Player
	var current_view_weapon: ViewWeapon


@export var current_scene: PackedScene

var _current_scene: Node
var _player_info: PlayerInfo = PlayerInfo.new()


static func toggle_mouse_mode() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


"""
static func set_up_view_weapon(view_weapon: ViewWeapon) -> void:
	view_weapon.event.connect(func (event_name: StringName, user_data: Variant) -> void:
		if event_name == &'shot':
			pass)
"""


static func set_up_player(player_info: PlayerInfo) -> void:
	var camera := Camera3D.new()
	var shotgun := V_SHOTGUN_SCENE.instantiate()
	var remote_transform := RemoteInterpolatedTransformer.new()

	player_info.player.inner_head.add_child.call_deferred(remote_transform)
	player_info.player.inner_head.add_child.call_deferred(camera)
	remote_transform.set_target.call_deferred(camera)
	camera.make_current.call_deferred()
	camera.add_child.call_deferred(shotgun)
	player_info.set.call_deferred(&'current_view_weapon', shotgun)
	player_info.player.get_tree().physics_frame.connect(func () -> void:
		shotgun.bob_animation_tree[&'parameters/blend_position'] = player_info.player.movement_axes.length_squared())
	#set_up_view_weapon.call_deferred(shotgun)


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	change_map(current_scene.instantiate())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE:
			toggle_mouse_mode()


func change_map(scene_root: Node) -> void:
	if is_instance_valid(_current_scene):
		_current_scene.queue_free()

	add_child.call_deferred(scene_root)
	set.call_deferred(&'_current_scene', scene_root)


func _on_node_added(node: Node) -> void:
	if node.is_in_group(GroupNames.ONLY_VISIBLE_IN_EDITOR):
		node.visible = false

	if node is Player:
		_player_info.player = node
		set_up_player(_player_info)
