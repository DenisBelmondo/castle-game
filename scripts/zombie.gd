extends Node3D


const Util := preload('res://scripts/util.gd')
const Character := preload('res://scripts/nodes/character.gd')
const CollisionLayers := preload('res://scripts/collision_layers.gd')
const Health := preload('res://scripts/health.gd')


enum State {
	LOOKING,
	CHASING,
}


@export var sight_targets: Array

var _sight_exclude: Array
var _state: State
var _target: Node3D
var _walk_velocity: Vector3

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var body: Character = %Character
@onready var heart: Node3D = %Heart
@onready var health: Health = %Health


func _ready() -> void:
	_sight_exclude = [ body ]
	health.depleted.connect(func () -> void:
		animation_player.play(&'die'))


func _physics_process(_delta: float) -> void:
	if _state == State.LOOKING:
		for target in sight_targets:
			var p := PhysicsRayQueryParameters3D.create(
				heart.global_position,
				target.global_position,
				CollisionLayers.SIGHT
			)

			var result := get_world_3d().direct_space_state.intersect_ray(p)

			if not result.is_empty():
				_target = result.collider
				_state = State.CHASING
	elif _state == State.CHASING:
		body.linear_velocity += body.global_position.direction_to(_target.global_position)
