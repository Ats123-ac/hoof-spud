## Top-down farmer. Movement and animation live here; *when* to move or swing is
## decided by the [StateMachine] child (see scripts/player/states/).
class_name Player
extends CharacterBody2D

## Emitted on the contact frame of a tool animation, after the hitbox has been
## placed. [param target] is the world position the swing landed on, which the
## crop and tilling systems (Parts 17-18) turn into a tile coordinate.
signal tool_swung(tool: StringName, target: Vector2)
signal tool_changed(tool: StringName, index: int)

## Both Sprout Lands character sheets use a 48x48 grid.
const CELL := Vector2i(48, 48)

const WALK_SHEET := "res://Assets/farming sprites/Characters/Basic Charakter Spritesheet.png"
const ACTION_SHEET := "res://Assets/farming sprites/Characters/Basic Charakter Actions.png"

## Row per facing on the 4x4 walk sheet.
const FACING_ROW: Dictionary[StringName, int] = {
	&"down": 0,
	&"up": 1,
	&"left": 2,
	&"right": 3,
}

## First row of each tool block on the 2x12 actions sheet. Each block holds four
## facings in the same order as [constant FACING_ROW], two frames per facing.
##
## Block order on the sheet was confirmed by eye, not assumed: row 0 swings a
## blade set perpendicular to the handle (hoe), row 4 swings a wedge head
## straddling the handle (axe), row 8 carries the watering can.
##
## The pack has no pickaxe animation, so "mine" borrows the hoe swing. Give it
## its own row here if you ever draw one.
const TOOL_ROW: Dictionary[StringName, int] = {
	&"chop": 4,
	&"mine": 0,
	&"till": 0,
	&"water": 8,
}

@export_group("Movement")
@export var speed: float = 60.0
@export var acceleration: float = 900.0
@export var friction: float = 1400.0

@export_group("Tools")
## Selection order for the tool_next / tool_prev actions. Each entry must match
## a key in [constant TOOL_ROW] *and* a state node under StateMachine.
@export var tools: Array[StringName] = [&"chop", &"mine", &"till", &"water"]
## How far in front of the player a swing reaches, in pixels.
@export var tool_reach: float = 14.0
@export var tool_damage: int = 1

@export_group("Animation")
@export var walk_fps: float = 8.0
@export var tool_fps: float = 6.0

## Last cardinal the player faced. Drives which directional clip plays.
var facing: Vector2 = Vector2.DOWN

var tool_index: int = 0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var tool_hitbox: Area2D = $ToolHitbox
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	sprite.sprite_frames = _build_frames()
	_place_hitbox()


func _physics_process(_delta: float) -> void:
	# Kept in front of the player every frame so the overlap list is already
	# correct by the time a swing queries it.
	_place_hitbox()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"tool_next"):
		cycle_tool(1)
	elif event.is_action_pressed(&"tool_prev"):
		cycle_tool(-1)


#region Input helpers used by states


func get_input_direction() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


## Steer toward [param direction] and remember it as the new facing.
func accelerate(direction: Vector2, delta: float) -> void:
	if not direction.is_zero_approx():
		facing = direction
	velocity = velocity.move_toward(direction * speed, acceleration * delta)


func decelerate(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


#endregion
#region Tools


func current_tool() -> StringName:
	return tools[tool_index] if not tools.is_empty() else &""


func cycle_tool(step: int) -> void:
	if tools.is_empty():
		return
	tool_index = wrapi(tool_index + step, 0, tools.size())
	tool_changed.emit(current_tool(), tool_index)


func select_tool(index: int) -> void:
	if index < 0 or index >= tools.size() or index == tool_index:
		return
	tool_index = index
	tool_changed.emit(current_tool(), tool_index)


## Fired by [PlayerTool] on the animation's contact frame.
func swing_tool() -> void:
	var tool_name := current_tool()
	tool_swung.emit(tool_name, tool_hitbox.global_position)

	for area in tool_hitbox.get_overlapping_areas():
		if area.has_method(&"take_hit"):
			area.take_hit(tool_name, tool_damage)


#endregion
#region Animation


## Play the clip for [param action] matching the current facing, e.g.
## `play_directional(&"walk")` -> "walk_left".
func play_directional(action: StringName) -> void:
	sprite.play("%s_%s" % [action, facing_name()])


## The current facing as one of "down", "up", "left" or "right".
func facing_name() -> StringName:
	if absf(facing.x) > absf(facing.y):
		return &"right" if facing.x > 0.0 else &"left"
	return &"down" if facing.y > 0.0 else &"up"


## The current facing snapped to a single cardinal unit vector.
func facing_cardinal() -> Vector2:
	match facing_name():
		&"up":
			return Vector2.UP
		&"left":
			return Vector2.LEFT
		&"right":
			return Vector2.RIGHT
		_:
			return Vector2.DOWN


func _place_hitbox() -> void:
	tool_hitbox.position = facing_cardinal() * tool_reach


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var walk := load(WALK_SHEET) as Texture2D
	for facing_key in FACING_ROW:
		var line: int = FACING_ROW[facing_key]
		SpriteSheet.add_clip(
			frames, walk, CELL, "walk_%s" % facing_key, SpriteSheet.row(line, 4), walk_fps
		)
		# Frame 0 of each walk cycle is the neutral standing pose.
		SpriteSheet.add_clip(
			frames, walk, CELL, "idle_%s" % facing_key, [Vector2i(0, line)], 1.0
		)

	var actions := load(ACTION_SHEET) as Texture2D
	for tool_name in TOOL_ROW:
		for facing_key in FACING_ROW:
			var line: int = TOOL_ROW[tool_name] + FACING_ROW[facing_key]
			SpriteSheet.add_clip(
				frames,
				actions,
				CELL,
				"%s_%s" % [tool_name, facing_key],
				SpriteSheet.row(line, 2),
				tool_fps,
				false
			)

	return frames


#endregion
