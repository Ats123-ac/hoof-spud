## Fades a tall prop while the player stands behind it, so a canopy never swallows
## the character. Attach as an Area2D on the prop with a shape covering the art.
##
## This is the reason props do not need oversized collision. Blocking the player
## far enough out that a tree can never overlap them means blocking them a full
## body-height away, which reads as an invisible wall; letting them walk to the
## trunk and fading the tree instead keeps both the movement and the sightline.
##
## Keep the node itself at the prop's origin and offset its CollisionShape2D
## upward to cover the art — [member Node2D.global_position] is then the same
## point Y-sorting compares, so the check for "is the player actually drawn
## behind this" needs nothing else.
class_name SeeThroughComponent
extends Area2D

## Sprite to fade. Usually the prop's Sprite2D.
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
	# Keep processing so the fade has time to run back out.
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


## True when something inside the prop's art is drawn behind it — that is, when it
## sits further up the screen, which is what Y-sorting orders on.
func is_obscuring() -> bool:
	for body in _inside:
		if is_instance_valid(body) and body.global_position.y < global_position.y:
			return true
	return false
