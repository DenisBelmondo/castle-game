@tool
extends Control


const Health := preload('res://scripts/health.gd')

var health: Health

@onready var health_label: Label = %HealthLabel
@onready var ammo_label: Label = %AmmoLabel
@onready var pickup_message: Label = %PickupMessage


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name': 'health',
			'type': TYPE_OBJECT,
			'hint': PROPERTY_HINT_NODE_TYPE,
			'usage': PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		},
	]


func _ready() -> void:
	health.updated.connect(func (__, ___) -> void: update())
	update()


func update() -> void:
	health_label.text = '%.0f' % ceilf(health.amount)
