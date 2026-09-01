## Drives its [State] children, forwarding process and input callbacks to
## whichever one is active.
##
## States are registered under their node name in snake_case, so a child called
## "Walk" is reached with `&"walk"` and one called "ToolUse" with `&"tool_use"`.
class_name StateMachine
extends Node

## Emitted after every successful switch.
signal state_changed(previous: StringName, current: StringName)

## State to enter on startup. Falls back to the first [State] child.
@export var initial_state: State

## Node the states operate on. Defaults to this machine's parent.
@export var agent: Node

## Name of the active state, or an empty [StringName] before startup.
var current_name: StringName = &""

var _current: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	if agent == null:
		agent = get_parent()

	for child in get_children():
		var state := child as State
		if state == null:
			push_warning("%s is not a State and will be ignored." % child.name)
			continue
		_states[_key(state)] = state
		state.agent = agent
		state.transitioned.connect(_on_state_transitioned)

	# Wait for siblings so states can safely touch the agent's @onready vars.
	if not owner.is_node_ready():
		await owner.ready

	var first := initial_state
	if first == null and not _states.is_empty():
		first = _states.values()[0]
	if first == null:
		push_error("%s has no states to start in." % name)
		set_process(false)
		set_physics_process(false)
		return

	_switch_to(_key(first))


func _process(delta: float) -> void:
	if _current:
		_current.update(delta)


func _physics_process(delta: float) -> void:
	if _current:
		_current.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _current:
		_current.handle_input(event)


## Switch to [param next]. Re-entering the active state is a no-op.
func travel(next: StringName) -> void:
	if next == current_name:
		return
	_switch_to(next)


func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)


func _switch_to(next: StringName) -> void:
	var target: State = _states.get(next)
	if target == null:
		push_error("%s has no state named '%s'." % [name, next])
		return

	var previous := current_name
	if _current:
		_current.exit()

	_current = target
	current_name = next
	_current.enter(previous)
	state_changed.emit(previous, next)


func _on_state_transitioned(next: StringName) -> void:
	travel(next)


func _key(state: State) -> StringName:
	return StringName(String(state.name).to_snake_case())
