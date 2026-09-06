## Kicks a sprite's shake shader and decays it back to rest.
##
## The target's material must be a [ShaderMaterial] exposing the float uniform named
## by [member parameter], marked `resource_local_to_scene` so each prop wobbles alone.

class_name ShakeComponent
extends Node

@export var target: CanvasItem

## Shader uniform to drive.
@export var parameter: StringName = &"shake_strength"

## Sway in pixels applied by a default-strength hit.
@export_range(0.0, 8.0) var strength: float = 2.0

## Pixels of sway shed per second.
@export_range(0.1, 40.0) var decay: float = 6.0

var _value: float = 0.0


func _ready() -> void:
	set_process(false)
	_apply()


## Starts or restarts a wobble; a negative [param amount] falls back to [member strength].
func shake(amount: float = -1.0) -> void:
	if target == null:
		return

	_value = strength if amount < 0.0 else amount
	_apply()
	set_process(true)


func _process(delta: float) -> void:
	_value = move_toward(_value, 0.0, decay * delta)
	_apply()
	if is_zero_approx(_value):
		set_process(false)


func _apply() -> void:
	if target == null:
		return
	var material := target.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter(parameter, _value)
