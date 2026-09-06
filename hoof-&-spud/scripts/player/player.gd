## Top-down farmer. Movement and animation live here; *when* to move or swing is
## decided by the [StateMachine] child in scripts/player/states/.
##
## Tools are [ToolData] resources: the bar renders their icons, the swing uses their
## damage, and tilling, watering and sowing branch on their kind. [member tools] can
## be edited per scene; left empty it falls back to [constant DEFAULT_TOOLS].

class_name Player
extends CharacterBody2D

## Emitted on the contact frame of a tool animation, after the hitbox has been
## placed. [param target] is the world position the swing landed on, which the
## farming systems turn into a tile coordinate.
signal tool_swung(tool: StringName, target: Vector2)
signal tool_changed(tool: StringName, index: int)

## Both character sheets use a 48x48 grid.
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

## First row of each tool block on the 2x12 actions sheet; a block holds four
## facings in [constant FACING_ROW] order, two frames each. `mine` borrows the hoe
## swing, which the sheet has no pickaxe animation for.
const TOOL_ROW: Dictionary[StringName, int] = {
	&"chop": 4,
	&"mine": 0,
	&"till": 0,
	&"water": 8,
}

## Used when the scene leaves [member tools] empty. Preloads keep this a
## compile-time constant.
const DEFAULT_TOOLS: Array[ToolData] = [
	preload("res://resources/tools/hoe.tres"),
	preload("res://resources/tools/watering_can.tres"),
	preload("res://resources/tools/axe.tres"),
	preload("res://resources/tools/mallet.tres"),
	preload("res://resources/tools/sow_wheat.tres"),
	preload("res://resources/tools/sow_eggplant.tres"),
]

## Direct-select actions in bar order: index i answers to `tool_i+1`.
const TOOL_ACTIONS: Array[StringName] = [
	&"tool_1", &"tool_2", &"tool_3", &"tool_4", &"tool_5", &"tool_6",
]

@export_group("Movement")
@export var speed: float = 60.0
@export var acceleration: float = 900.0
@export var friction: float = 1400.0

@export_group("Tools")
## Bar order. Each entry's [member ToolData.id] matches a state node under
## StateMachine (`Chop` -> `&"chop"`) and its [member ToolData.animation] a block
## in [constant TOOL_ROW].
@export var tools: Array[ToolData] = []
## How far in front of the player a swing reaches, in pixels.
@export var tool_reach: float = 14.0

@export_group("Animation")
@export var walk_fps: float = 8.0
@export var tool_fps: float = 6.0

## Last cardinal faced; drives which directional clip plays.
var facing: Vector2 = Vector2.DOWN

var tool_index: int = 0

var _step_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var tool_hitbox: Area2D = $ToolHitbox
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	if tools.is_empty():
		tools = DEFAULT_TOOLS.duplicate()
	sprite.sprite_frames = _build_frames()
	_place_hitbox()


## Keeps the hitbox in front of the player so its overlap list is already correct
## by the time a swing queries it.
func _physics_process(_delta: float) -> void:
	_place_hitbox()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"tool_next"):
		cycle_tool(1)
	elif event.is_action_pressed(&"tool_prev"):
		cycle_tool(-1)
	elif event.is_action_pressed(&"interact"):
		_try_interact()
	else:
		for index in TOOL_ACTIONS.size():
			if event.is_action_pressed(TOOL_ACTIONS[index]):
				select_tool(index)
				return


func _try_interact() -> void:
	var target := InteractableComponent.nearest_to(self)
	if target != null and target.try_interact():
		return


#region Input helpers used by states


func get_input_direction() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


## Steers toward [param direction] and remembers it as the new facing.
func accelerate(direction: Vector2, delta: float) -> void:
	if not direction.is_zero_approx():
		facing = direction
	velocity = velocity.move_toward(direction * speed, acceleration * delta)


func decelerate(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


## One soft footfall per stride while actually moving; the timer keeps it off the
## physics-frame rate.
func tick_footstep(delta: float) -> void:
	_step_timer -= delta
	if _step_timer > 0.0 or velocity.length() < speed * 0.35:
		return
	_step_timer = 0.32
	Audio.play(&"step", 0.14, -8.0)


#endregion
#region Tools


func current_tool_data() -> ToolData:
	if tool_index < 0 or tool_index >= tools.size():
		return null
	return tools[tool_index]


func current_tool() -> StringName:
	var data := current_tool_data()
	return data.id if data != null else &""


func cycle_tool(step: int) -> void:
	if tools.is_empty():
		return
	select_tool(wrapi(tool_index + step, 0, tools.size()))


func select_tool(index: int) -> void:
	if index < 0 or index >= tools.size() or index == tool_index:
		return
	tool_index = index
	tool_changed.emit(current_tool(), tool_index)
	Audio.play(&"ui_move", 0.0)


## Called by [PlayerTool] on the animation's contact frame.
func swing_tool() -> void:
	var data := current_tool_data()
	var tool_name := data.id if data != null else &""
	tool_swung.emit(tool_name, tool_hitbox.global_position)

	# Only striking tools damage; a watering can must not headbutt a tree.
	if data == null or data.kind != ToolData.Kind.STRIKE:
		return

	for area in tool_hitbox.get_overlapping_areas():
		if area.has_method(&"take_hit"):
			area.take_hit(tool_name, data.damage)


#endregion
#region Animation


## Plays the clip for [param action] matching the current facing, so
## `play_directional(&"walk")` becomes `walk_left`.
func play_directional(action: StringName) -> void:
	sprite.play("%s_%s" % [action, facing_name()])


func facing_name() -> StringName:
	if absf(facing.x) > absf(facing.y):
		return &"right" if facing.x > 0.0 else &"left"
	return &"down" if facing.y > 0.0 else &"up"


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


## Cuts both sheets into directional clips. Frame 0 of each walk cycle doubles as
## the neutral standing pose.
func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var walk := load(WALK_SHEET) as Texture2D
	for facing_key in FACING_ROW:
		var line: int = FACING_ROW[facing_key]
		SpriteSheet.add_clip(
			frames, walk, CELL, "walk_%s" % facing_key, SpriteSheet.row(line, 4), walk_fps
		)
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
