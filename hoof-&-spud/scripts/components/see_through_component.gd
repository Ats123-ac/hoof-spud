## Fades a tall prop while the player is drawn behind it, so a canopy never swallows
## the character.
##
## Keep the node at the prop's origin and offset its shape upward over the art:
## [member Node2D.global_position] is then the same point Y-sorting orders on.

class_name SeeThroughComponent
extends Area2D

## Sprite to fade, usually the prop's Sprite2D.
@export var target: CanvasItem

## Opacity held while the player is behind the prop.
@export_range(0.0, 1.0) var faded_alpha: float = 0.45

## Higher fades in and out more sharply.
@export_range(0.5, 30.0) var fade_speed: float = 10.0

var _inside: Array[Node2D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_process(false)


func _on_body_entered(body: Node2D) -> void:
	if not _inside.has(body):
		_inside.append(body)
	set_process(true)


func _on_body_exited(body: Node2D) -> void:
	_inside.erase(body)
	set_process(true)


func _process(delta: float) -> void:
	if target == null:
		set_process(false)
		return

	var wanted := faded_alpha if is_obscuring() else 1.0
	var weight := 1.0 - exp(-fade_speed * delta)
	target.modulate.a = lerpf(target.modulate.a, wanted, weight)

	# Settle exactly on 1.0 rather than creeping toward it forever.
	if is_equal_approx(wanted, 1.0) and absf(target.modulate.a - 1.0) < 0.01:
		target.modulate.a = 1.0
		set_process(false)


## True when something inside the prop's art is drawn behind it, which is to say
## further up the screen.
func is_obscuring() -> bool:
	for body in _inside:
		if is_instance_valid(body) and body.global_position.y < global_position.y:
			return true
	return false
