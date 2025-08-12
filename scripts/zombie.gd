extends Node3D


const Util := preload('res://scripts/util.gd')
const Character := preload('res://scripts/nodes/character.gd')
const CollisionLayers := preload('res://scripts/collision_layers.gd')
const Health := preload('res://scripts/health.gd')


enum State {
	LOOKING,
	CHASING,
	DYING,
}


signal poop(thing: Node3D)

@export var sight_targets: Array

var _sight_exclude: Array
var _state: State
var _target: Node3D
var _walk_velocity: Vector3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var character: Character = %Character
@onready var heart: Node3D = %Heart
@onready var health: Health = %Health
@onready var hitbox: Area3D = %Hitbox


func _ready() -> void:
	_sight_exclude = [ character ]
	health.depleted.connect(_on_health_depleted)

	var f := func (thing: Node3D) -> void:
		if thing == character:
			return

		poop.emit(thing)

	hitbox.area_entered.connect(f)
	hitbox.body_entered.connect(f)


func _physics_process(_delta: float) -> void:
	if _state == State.LOOKING:
		for target in sight_targets:
			var p := PhysicsRayQueryParameters3D.create(
				heart.global_position,
				target.global_position,
				CollisionLayers.CHARACTERS
			)

			var result := get_world_3d().direct_space_state.intersect_ray(p)

			if not result.is_empty():
				_target = result.collider
				_state = State.CHASING
	elif _state == State.CHASING:
		character.linear_velocity += character.global_position.direction_to(_target.global_position) / 3


func _on_health_depleted() -> void:
	_state = State.DYING
	character.body.collision_layer = 0
	character.body.collision_mask &= ~CollisionLayers.CHARACTERS
	hitbox.collision_layer = 0
	hitbox.collision_mask &= ~CollisionLayers.CHARACTERS
	animation_player.play(&'die')
