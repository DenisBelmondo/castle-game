extends Area3D

#
# signals
#

signal entered
signal exited

#
# export values
#

@export var _is_active : bool = true

#//#
@export_group("Delay options")
@export var delay_enter : bool = false
@export var delay_exit : bool = false
@export_range(0, 1000, 0.1) var Delay_enter_time : float = 0
@export_range(0, 1000, 0.1) var Delay_exit_time : float = 0

#//#
@export_group("Destroy options")
@export var destroy_on_touch: bool = false
@export var Destroy_on_leave: bool = false

#//#
@export_group("Text options")
@export var display_mode : bool = false
@export_multiline var display_text : String = ""
@export_range(-1, 1000, 0.1) var Display_text_fade_time : float

#onready variables
@onready var display_label = $DisplayLabel

#//////////////////////////////////////////////////////////#

func _ready():
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)
	display_label.hide()

	display_label.text = display_text


func _physics_process(_delta):
	if _is_active:
		monitoring = true
	else:
		monitoring = false


func _on_entered(_body):
	if !delay_enter:
		entered.emit()

	if display_mode:
		if Display_text_fade_time != -1:
			display_label.modulate.a = 0
			display_label.show()

			var fade_tween = get_tree().create_tween()

			fade_tween.tween_property(display_label, "modulate:a", 1.0, Display_text_fade_time)
		else:
			display_label.show()

	if delay_enter:
		await get_tree().create_timer(Delay_enter_time).timeout
		entered.emit()

	if destroy_on_touch:
		queue_free()


func _on_exited(_body):
	if !delay_exit:
		exited.emit()

	if display_mode:
		if Display_text_fade_time != -1:
			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(display_label, "modulate:a", 0.0, Display_text_fade_time)
			await fade_tween.finished
			display_label.hide()
		else:
			display_label.hide()

	if delay_exit:
		await get_tree().create_timer(Delay_exit_time).timeout
		exited.emit()

	if Destroy_on_leave:
		queue_free()

func activate():
	_is_active = true

func deactivate():
	_is_active = false
	display_label.hide()
