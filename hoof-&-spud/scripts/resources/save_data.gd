## Everything worth remembering between sessions (Part 19).
##
## A [Resource] rather than a JSON blob because Godot then does the typing for us:
## a [Vector2] comes back as a [Vector2], and adding a field here is the whole
## migration. [member version] exists so an old save can be spotted and skipped
## instead of half-loading into a broken farm.
class_name SaveData
extends Resource

## Bump whenever a field changes meaning. Saves with a different number are
## rejected by [SaveGame].
const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION

## Wall-clock stamp of the last write, for the Continue button's subtitle.
@export var saved_at: String = ""

# --- clock -------------------------------------------------------------------

@export var day: int = 1
@export var minutes: float = 360.0

# --- player ------------------------------------------------------------------

@export var player_position: Vector2 = Vector2.ZERO
@export var player_facing: StringName = &"down"
@export var tool_index: int = 0

## Item id to count, straight from [code]Inventory.snapshot()[/code].
@export var inventory: Dictionary[StringName, int] = {}

# --- farm --------------------------------------------------------------------

## Cells the player has hoed.
@export var tilled: Array[Vector2i] = []

## Subset of [member tilled] that is still damp.
@export var watered: Array[Vector2i] = []

## One entry per planted cell:
## [code]{cell: Vector2i, crop: StringName, stage: int, growth: int, watered: bool}[/code].
@export var crops: Array[Dictionary] = []

# --- world -------------------------------------------------------------------

## Trees and rocks that were harvested and have not grown back:
## [code]{name: String, health: int, depleted: bool, respawn: float}[/code].
@export var harvestables: Array[Dictionary] = []

## Chest contents keyed by node name:
## [code]{name: String, items: Dictionary}[/code].
@export var chests: Array[Dictionary] = []

## Animals, so a fed cow stays fed:
## [code]{name: String, position: Vector2, fed: bool, ready: bool, days: int}[/code].
@export var animals: Array[Dictionary] = []

## Names of NPCs the player has already talked to, so first-meeting lines only
## play once.
@export var met: Array[String] = []


func is_compatible() -> bool:
	return version == CURRENT_VERSION
