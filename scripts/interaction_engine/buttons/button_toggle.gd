extends Area3D


const Static := preload('res://scripts/interaction_engine/static.gd')

signal on
signal off

@export_group("Standard")
@export_range(-1,1000,1) var use_amount : int = -1
@export var _is_active : bool = true
@export var pop_out_delay: float = -1
@export_group("Text")
@export var display_mode : bool = false
@export_multiline var currently_display_text : String = ""

@onready var display_label = $DisplayLabel

var button_pressed : bool = false
var inside : bool = false
var being_pressed : bool = false


func _ready() -> void:
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)
	display_label.hide()

	display_label.text = currently_display_text


func _physics_process(_delta: float) -> void:
	monitoring = _is_active


func _on_entered(_body) -> void:
	inside = true
	display_text()


func _on_exited(_body) -> void:
	inside = false
	display_text()


func press() -> void:
	being_pressed = true
	if pop_out_delay == -1:
		if button_pressed:
			button_pressed = false
			off.emit()
		else:
			button_pressed = true
			on.emit()
	else:
		display_label.hide()
		if button_pressed:
			off.emit()
			await get_tree().create_timer(pop_out_delay).timeout
			button_pressed = false
		else:
			on.emit()
			await get_tree().create_timer(pop_out_delay).timeout
			button_pressed = true


	if use_amount != -1:
		use_amount -= 1

	if use_amount == 0:
		queue_free()

	being_pressed = false

	if inside:
		display_text()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(Static.INTERACT_INPUT_ACTION_NAME):
		if _is_active and inside and !being_pressed:
			press()


func activate() -> void:
	_is_active = true


func deactivate() -> void:
	_is_active = false
	display_label.hide()


func display_text() -> void:
	if display_mode and !being_pressed:
		if inside:
			display_label.show()
		else:
			display_label.hide()
