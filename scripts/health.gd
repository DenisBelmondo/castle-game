@tool
extends Node


const CastleGameUtil := preload('res://scripts/castle_game_util.gd')
const Health := preload('health.gd')

signal updated(new_amount: float, old_amount: float)
signal healed(amount: float, user_data: Variant)
signal damaged(amount: float, user_data: Variant)
signal depleted

var amount: float = 100:
	set(value):
		var old_value := amount
		amount = value
		updated.emit(amount, old_value)


func _enter_tree() -> void:
	CastleGameUtil.set_meta_on(get_parent(), Health, self)


func _exit_tree() -> void:
	CastleGameUtil.remove_meta_from(get_parent(), Health)


func heal(p_amount: float, user_data: Variant = null) -> void:
	amount += p_amount
	healed.emit(p_amount, user_data)


func damage(p_amount: float, user_data: Variant = null) -> void:
	amount -= p_amount
	damaged.emit(p_amount, user_data)

	if amount <= 0:
		depleted.emit()
