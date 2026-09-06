## Everything worth remembering between sessions.
##
## A [Resource] rather than a JSON blob, so Godot does the typing: a [Vector2] comes
## back as a [Vector2], and adding a field here is the whole migration.
## [member version] lets an old save be spotted and skipped instead of half-loading
## into a broken farm.

class_name SaveData
extends Resource

## Bump whenever a field changes meaning; saves with a different number are
## rejected by [SaveGame].
const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION

## Wall-clock stamp of the last write, for the Continue button's subtitle.
@export var saved_at: String = ""


@export var day: int = 1
@export var minutes: float = 360.0


@export var player_position: Vector2 = Vector2.ZERO
@export var player_facing: StringName = &"down"
@export var tool_index: int = 0

## Item id to count, straight from [method Inventory.snapshot].
@export var inventory: Dictionary[StringName, int] = {}


## Cells the player has hoed.
@export var tilled: Array[Vector2i] = []

## Subset of [member tilled] that is still damp.
@export var watered: Array[Vector2i] = []

## One entry per planted cell: `{cell, crop, stage, growth, watered}`.
@export var crops: Array[Dictionary] = []


## Props harvested and not yet grown back: `{name, health, depleted, respawn}`.
@export var harvestables: Array[Dictionary] = []

## Chest contents keyed by node name: `{name, items}`.
@export var chests: Array[Dictionary] = []

## Per animal, so a fed cow stays fed across a reload.
@export var animals: Array[Dictionary] = []

## NPCs already talked to, so first-meeting lines play once.
@export var met: Array[String] = []


func is_compatible() -> bool:
	return version == CURRENT_VERSION
