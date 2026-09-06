## Autoload that fades the screen out, swaps the scene underneath, and fades back.
##
## A swap is atomic: requests made mid-transition are coalesced, so a double-clicked
## button cannot start two loads at once.

extends Node

signal scene_changing(path: String)

signal scene_swapped(path: String)

const OVERLAY_LAYER := 100

const FADE_SECONDS := 0.45

## Handed from the outgoing scene to the incoming one, for door spawns or cutscenes.
var payload: Dictionary = {}

var _overlay: ColorRect
var _busy: bool = false
var _pending: String = ""


func _ready() -> void:
	# The fade has to run while a menu holds the tree paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var layer := CanvasLayer.new()
	layer.name = &"SceneSwapLayer"
	layer.layer = OVERLAY_LAYER
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.name = &"SceneSwapFade"
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.modulate.a = 0.0
	layer.add_child(_overlay)


func change_scene(path: String, fade: float = FADE_SECONDS) -> void:
	if _busy:
		_pending = path
		return

	_busy = true
	scene_changing.emit(path)

	await fade_out(fade)
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneSwap could not load %s: %s" % [path, error_string(error)])
		_busy = false
		return

	# Let the new scene finish _ready before revealing it.
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in(fade)

	scene_swapped.emit(path)
	_busy = false

	if _pending != "":
		var next := _pending
		_pending = ""
		change_scene(next, fade)


func fade_out(duration: float = FADE_SECONDS) -> void:
	if duration <= 0.0:
		_overlay.modulate.a = 1.0
		return
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func fade_in(duration: float = FADE_SECONDS) -> void:
	if duration <= 0.0:
		_overlay.modulate.a = 0.0
		return
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, duration)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished


## True while a transition is in flight; menus ignore input during one.
func is_swapping() -> bool:
	return _busy
