## Static description of one collectable item type.
##
## Instances live in resources/items/, so a stack of wood is a reference to the same
## [ItemData] plus a count; the inventory and chests both key off [member id].

class_name ItemData
extends Resource

## Stable key used by the inventory and by save data.
@export var id: StringName = &""

## Player-facing name.
@export var display_name: String = ""

## 16x16 icon, normally an [AtlasTexture] cut from a shared sheet.
@export var icon: Texture2D

@export_range(1, 999) var max_stack: int = 99
