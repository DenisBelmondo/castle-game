#
# mason: ripped straight from my personal project. this is a linear state
# machine. i'll write examples later.
#

extends Object


enum ProcessMode {
	PROCESS,
	PHYSICS,
	CUSTOM,
}


var process_mode := ProcessMode.PROCESS
var current_state: StringName
var previous_state: StringName
var states: Dictionary[StringName, Variant]


static func create() -> RefCounted:
	var rc := RefCounted.new()
	rc.set_script(preload('state_machine.gd'))
	return rc


func _init(p_states: Dictionary[StringName, Variant] = {}) -> void:
	states = p_states


func _physics_process(delta: float) -> void:
	if process_mode == ProcessMode.PHYSICS:
		process(delta)


func _process(delta: float) -> void:
	if process_mode == ProcessMode.PROCESS:
		process(delta)


func process(delta: float) -> void:
	var current_state_obj: Variant = states.get(current_state)
	var enter_func := Callable()
	var process_func := Callable()
	var context: Variant

	if not is_instance_valid(current_state_obj):
		return

	if &'enter' in current_state_obj:
		assert(current_state_obj.enter is Callable, 'enter is not a callable')
		enter_func = current_state_obj.enter

	if &'process' in current_state_obj:
		assert(current_state_obj.process is Callable, 'process is not a callable')
		process_func = current_state_obj.process

	if &'context' in current_state_obj:
		context = current_state_obj.context
		enter_func = enter_func.bind(context)
		process_func = process_func.bind(context)

	if previous_state != current_state:
		enter_state(current_state)

	previous_state = current_state

	var state_result = process_func.call(delta)

	if state_result is Array:
		if state_result[0] == &'goto':
			current_state = state_result[1]
			enter_state(current_state)


func enter_state(state: StringName) -> void:
	var current_state_obj: Variant = states.get(current_state)
	var enter_func := Callable()
	var context: Variant

	if &'enter' in current_state_obj:
		assert(current_state_obj.enter is Callable, 'enter is not a callable')
		enter_func = current_state_obj.enter

	if &'context' in current_state_obj:
		context = current_state_obj.context
		enter_func = enter_func.bind(context)

	if enter_func.is_valid():
		enter_func.call()
