## Overbrightens a sprite for a few frames on impact.
##
## Uses [member CanvasItem.modulate] above 1.0, which brightens in Godot's 2D
## renderer, so it needs no shader and composes with the shake shader.
class_name HitFlashComponent
extends Node

@export var target: CanvasItem

@export_range(0.02, 1.0) var duration: float = 0.12

## Multiplier applied on impact. 1.0 is no flash.
@export_range(1.0, 6.0) var brightness: float = 2.5

var _tween: Tween


func flash() -> void:
	if target == null:
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	var alpha := target.modulate.a
	target.modulate = Color(brightness, brightness, brightness, alpha)

	_tween = create_tween()
	_tween.tween_property(target, "modulate", Color(1.0, 1.0, 1.0, alpha), duration)
