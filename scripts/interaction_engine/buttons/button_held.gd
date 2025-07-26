extends Area3D


const Static := preload('res://scripts/interaction_engine/static.gd')

signal pressed
signal depressed
signal finished

@export_group("Standard")
@export_range(-1,1000,1) var use_time : int = -1
@export var _is_active : bool = true
@export var die_on_use : bool = true
@export_group("Text")
@export var display_mode : bool = false
@export_multiline var enter_text : String = ""

@onready var display_label = $DisplayLabel
@onready var progress_bar = $ProgressBar

var current_use_time : float = 0
var button_is_held : bool = false
var is_inside : bool = false
var is_finished : bool = false


func _ready() -> void:
	area_entered.connect(entered)
	area_exited.connect(_on_exited)
	display_label.hide()

	display_label.text = enter_text
	progress_bar.max_value = use_time


func _physics_process(delta: float) -> void:
	monitoring = _is_active

	if button_is_held:
		current_use_time += 1 * delta
		progress_bar.show()

	if current_use_time >= use_time:
		is_finished = true
		reset()

	progress_bar.value = current_use_time


func entered(_body) -> void:
	is_inside = true
	display_text()


func _on_exited(_body) -> void:
	button_is_held = false
	current_use_time = 0
	is_inside = false
	display_text()


func press() -> void:
	button_is_held = true
	pressed.emit()


func depress() -> void:
	current_use_time = 0
	button_is_held = false
	depressed.emit()


func reset() -> void:
	if is_finished:
		finished.emit()

	is_finished = false
	current_use_time = 0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(Static.INTERACT_INPUT_ACTION_NAME):
		if _is_active and is_inside:
			press()

	if event.is_action_released(Static.INTERACT_INPUT_ACTION_NAME):
		if _is_active and is_inside:
			depress()


func activate() -> void:
	_is_active = true


func deactivate() -> void:
	button_is_held = false
	_is_active = false
	display_label.hide()


func display_text() -> void:
	if display_mode:
		if is_inside:
			if !button_is_held:
				display_label.show()
		else:
			display_label.hide()
			progress_bar.hide()
