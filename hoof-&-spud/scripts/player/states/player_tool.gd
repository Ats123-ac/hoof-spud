## One swing of a tool. Shared by the Chop, Till and Water state nodes — they
## differ only in the exported [member animation], which is why the state name
## matches the animation prefix and the tool name in [member Player.tools].
extends State

## Animation prefix on the player's [SpriteFrames], e.g. "chop" -> "chop_left".
@export var animation: StringName = &"chop"

## Frame index the swing connects on. The Sprout Lands action clips are two
## frames, so the contact is the second one.
@export var hit_frame: int = 1

var _player: Player
var _has_hit: bool = false


func enter(_previous: StringName) -> void:
	_player = agent as Player
	_has_hit = false
	_player.velocity = Vector2.ZERO

	_player.sprite.frame_changed.connect(_on_frame_changed)
	_player.sprite.animation_finished.connect(_on_animation_finished)
	_player.play_directional(animation)


func exit() -> void:
	_player.sprite.frame_changed.disconnect(_on_frame_changed)
	_player.sprite.animation_finished.disconnect(_on_animation_finished)


func physics_update(_delta: float) -> void:
	# Rooted for the duration of the swing.
	_player.velocity = Vector2.ZERO
	_player.move_and_slide()


func _on_frame_changed() -> void:
	if _has_hit or _player.sprite.frame < hit_frame:
		return
	_has_hit = true
	_player.swing_tool()


func _on_animation_finished() -> void:
	if not _has_hit:
		_player.swing_tool()
	transitioned.emit(&"idle")
