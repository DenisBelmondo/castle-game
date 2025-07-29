extends Area3D


const Static := preload('res://scripts/interaction_engine/static.gd')

signal pressed
signal depressed

@export_group("Standard")
@export_range(-1,1000,1) var use_amount : int = -1
@export var _is_active : bool = true
@export_range(-1,1000,0.1) var pop_out_delay : float = 5.0
@export_group("Text")
@export var display_mode : bool = false
@export_multiline var enter_text : String = ""
@export_multiline var Description_text : String = ""
@export_range(0,100,0.1) var Description_text_fade_time : float = 5.0

@onready var display_label = $DisplayLabel
@onready var description_label = $DescriptionLabel


var button_pressed : bool = false
var is_inside : bool = false


func _ready() -> void:
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)
	display_label.hide()
	description_label.hide()

	display_label.text = enter_text
	description_label.text = Description_text


func _physics_process(_delta: float) -> void:
	monitoring = _is_active


func _on_entered(_body) -> void:
	is_inside = true
	display_text()


func _on_exited(_body) -> void:
	is_inside = false
	display_text()


func press() -> void:
	if !button_pressed:
		if pop_out_delay == -1:
			pressed.emit()
			button_pressed = true
			depressed.emit()
			button_pressed = false
		elif !display_mode:
			pressed.emit()
			button_pressed = true
			await get_tree().create_timer(pop_out_delay).timeout
			depressed.emit()
			button_pressed = false
		else:
			pressed.emit()
			button_pressed = true
			display_label.hide()
			description_label.modulate.a = 1
			description_label.show()
			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(description_label, "modulate:a", 0, Description_text_fade_time)
			await get_tree().create_timer(pop_out_delay).timeout
			description_label.hide()

			if is_inside:
				description_label.modulate.a = 1
				display_label.show()

			depressed.emit()
			button_pressed = false

		if use_amount != -1:
			use_amount -= 1
		if use_amount == 0:
			queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(Static.INTERACT_INPUT_ACTION_NAME):
		if _is_active and is_inside:
			press()


func activate() -> void:
	_is_active = true


func deactivate() -> void:
	_is_active = false
	display_label.hide()


func display_text() -> void:
	if display_mode:
		if is_inside:
			if !button_pressed:
				display_label.show()
			description_label.hide()
		else:
			display_label.hide()
