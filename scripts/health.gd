@tool
extends Node


const Health := preload('health.gd')

signal updated(new_amount: float, old_amount: float)
signal healed(amount: float, user_data: Variant)
signal damaged(amount: float, user_data: Variant)

var target: Node

var amount: float = 100:
	set(value):
		var old_value := amount
		amount = value
		updated.emit(amount, old_value)


static func get_from(node: Node) -> Health:
	if node.has_meta(&'health'):
		return node.get_meta(&'health')

	return null


func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name': 'target',
			'type': TYPE_OBJECT,
			'hint': PROPERTY_HINT_NODE_TYPE,
			'usage': PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		},
		{
			'name': 'amount',
			'type': TYPE_FLOAT,
			'usage': PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		},
	]


func _enter_tree() -> void:
	if not is_instance_valid(target):
		target = get_parent()

	attach_to(target)


func _exit_tree() -> void:
	detach_from(target)


func attach_to(node: Node) -> void:
	if not Engine.is_editor_hint():
		node.set_meta(&'health', self)


func detach_from(node: Node) -> void:
	if not Engine.is_editor_hint():
		if node.has_meta(&'health'):
			node.remove_meta(&'health')


func heal(p_amount: float, user_data: Variant = null) -> void:
	amount += p_amount
	healed.emit(p_amount, user_data)


func damage(p_amount: float, user_data: Variant = null) -> void:
	amount -= p_amount
	damaged.emit(p_amount, user_data)
