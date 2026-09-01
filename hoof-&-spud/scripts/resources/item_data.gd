## Static description of one collectable item type.
##
## Instances live in resources/items/ so a stack of wood is just a reference to
## the same [ItemData] plus a count — the inventory (Part 15) and chests
## (Part 22) both key off [member id].
class_name ItemData
extends Resource

## Stable key used by the inventory and by save data. Never localise this.
@export var id: StringName = &""

## Player-facing name.
@export var display_name: String = ""

## 16x16 icon, normally an [AtlasTexture] cut from a shared sheet.
@export var icon: Texture2D

@export_range(1, 999) var max_stack: int = 99
