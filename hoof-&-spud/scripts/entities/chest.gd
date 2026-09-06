## A storage chest: the player's satchel on one side, a private stack dictionary on
## the other, with [ChestPanel] moving items between them.
##
## Contents are plain id -> count, the same shape the inventory uses, so saving is a
## dictionary copy. Stack limits belong to whoever moves an item into the satchel.

class_name Chest
extends Node2D

signal opened
signal closed_chest

## Lid-up art; the closed sprite is whatever the scene ships.
@export var open_texture: Texture2D

## id -> count.
var items: Dictionary[StringName, int] = {}

var is_open: bool = false

var _panel: ChestPanel
var _closed_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite
@onready var interact: InteractableComponent = $Interact


func _ready() -> void:
	add_to_group(&"chest")
	_closed_texture = sprite.texture
	interact.interacted.connect(_on_interacted)
	_set_lid(false)


func _on_interacted(_component: InteractableComponent) -> void:
	if is_open:
		return
	_open()


func _open() -> void:
	if _panel != null and is_instance_valid(_panel):
		return

	is_open = true
	interact.enabled = false
	_set_lid(true)
	Audio.play(&"chest_open")
	opened.emit()

	_panel = preload("res://scenes/ui/chest_panel.tscn").instantiate()
	get_tree().root.add_child(_panel)
	_panel.closed.connect(_on_panel_closed)
	_panel.setup(self)


func _on_panel_closed() -> void:
	_panel = null
	is_open = false
	interact.enabled = true
	_set_lid(false)
	closed_chest.emit()


## Chests do not enforce stack sizes, so this always takes everything; the return
## value is what was actually added.
func add(id: StringName, amount: int) -> int:
	if id == &"" or amount <= 0:
		return 0
	items[id] = items.get(id, 0) + amount
	return amount


## Removes up to [param amount]; returns how many actually left.
func take(id: StringName, amount: int) -> int:
	var held: int = items.get(id, 0)
	var taken := mini(held, amount)
	if taken <= 0:
		return 0
	var left := held - taken
	if left <= 0:
		items.erase(id)
	else:
		items[id] = left
	return taken


func count(id: StringName) -> int:
	return items.get(id, 0)


# The open sprite is taller (raised lid), so the offset drops to keep the base of
# the chest on the node origin either way.
func _set_lid(open: bool) -> void:
	if open and open_texture != null:
		sprite.texture = open_texture
		sprite.offset = Vector2(0, -12)
	else:
		sprite.texture = _closed_texture
		sprite.offset = Vector2(0, -8)
