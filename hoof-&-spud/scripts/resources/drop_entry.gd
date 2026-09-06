## One possible drop: an item, a quantity range and a chance to roll at all.

class_name DropEntry
extends Resource

@export var item: ItemData

@export_range(0, 99) var min_amount: int = 1
@export_range(0, 99) var max_amount: int = 1

## Probability this entry drops anything, 0 (never) to 1 (always).
@export_range(0.0, 1.0) var chance: float = 1.0
