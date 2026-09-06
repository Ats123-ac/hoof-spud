## Two grids facing each other: the chest on the left, the satchel on the right.
## Click moves one item, shift-click moves a stack.
##
## Stack limits are enforced only on the way into the satchel, because that is the
## side [member ItemData.max_stack] applies to; a chest will hold ninety-nine of
## anything in one slot.

class_name ChestPanel
extends CanvasLayer

signal closed

const CHEST_SLOTS := 12
const BAG_SLOTS := 24
const COLUMNS := 6
const SLOT_SIZE := Vector2(28, 28)
const ICON_SIZE := Vector2(20, 20)

const EMPTY_DIM := Color(0.62, 0.58, 0.52, 0.7)
const FILLED := Color(1.0, 1.0, 1.0, 1.0)

var chest: Chest
var _chest_slots: Array[Dictionary] = []
var _bag_slots: Array[Dictionary] = []
var _closed := false

@onready var chest_grid: GridContainer = %ChestGrid
@onready var bag_grid: GridContainer = %SatchelGrid


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"modal")

	for index in CHEST_SLOTS:
		_chest_slots.append(_build_slot(chest_grid, true))
	for index in BAG_SLOTS:
		_bag_slots.append(_build_slot(bag_grid, false))

	get_tree().paused = true
	_refresh()


## Called by [Chest] right after the node enters the tree.
func setup(source: Chest) -> void:
	chest = source
	if is_inside_tree():
		_refresh()


func _build_slot(grid: GridContainer, is_chest: bool) -> Dictionary:
	var panel := Panel.new()
	panel.custom_minimum_size = SLOT_SIZE

	var icon := TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = ICON_SIZE
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)

	var count := Label.new()
	count.add_theme_font_size_override(&"font_size", 8)
	count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count.offset_left = -24
	count.offset_top = -12
	count.offset_right = -2
	count.offset_bottom = -1
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(count)

	var slot := {"panel": panel, "icon": icon, "count": count, "id": &""}
	panel.gui_input.connect(_on_slot_input.bind(is_chest, slot))
	grid.add_child(panel)
	return slot


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_slot_input(event: InputEvent, is_chest: bool, slot: Dictionary) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return

	var id: StringName = slot["id"]
	if id == &"":
		return
	var whole := mouse.shift_pressed

	if is_chest:
		_move_chest_to_bag(id, whole)
	else:
		_move_bag_to_chest(id, whole)


func _move_chest_to_bag(id: StringName, whole: bool) -> void:
	if chest == null:
		return
	var data := ItemRegistry.data(id)
	var room := (data.max_stack if data != null else 99) - Inventory.count(id)
	if room <= 0:
		Audio.play(&"deny", 0.0)
		return

	var wanted := chest.count(id) if whole else 1
	var taken := chest.take(id, mini(wanted, room))
	if taken <= 0:
		return
	Inventory.add(id, taken)
	Audio.play(&"ui_click", 0.0)
	_refresh()


func _move_bag_to_chest(id: StringName, whole: bool) -> void:
	if chest == null:
		return
	var wanted := Inventory.count(id) if whole else 1
	var taken := Inventory.remove(id, wanted)
	if taken <= 0:
		return
	chest.add(id, taken)
	Audio.play(&"ui_click", 0.0)
	_refresh()


func _refresh() -> void:
	var chest_ids: Array[StringName] = []
	if chest != null:
		for id in chest.items.keys():
			if int(chest.items[id]) > 0:
				chest_ids.append(StringName(id))

	var snapshot := Inventory.snapshot()
	var bag_ids: Array[StringName] = []
	for id in snapshot.keys():
		if int(snapshot[id]) > 0:
			bag_ids.append(StringName(id))

	_paint(_chest_slots, chest_ids, chest.items if chest != null else {})
	_paint(_bag_slots, bag_ids, snapshot)


func _paint(slots: Array[Dictionary], ids: Array[StringName], counts: Dictionary) -> void:
	for index in slots.size():
		var slot: Dictionary = slots[index]
		if index >= ids.size():
			slot["id"] = &""
			slot["icon"].texture = null
			slot["count"].text = ""
			slot["panel"].self_modulate = EMPTY_DIM
			slot["panel"].tooltip_text = ""
			continue

		var id: StringName = ids[index]
		var data := ItemRegistry.data(id)
		slot["id"] = id
		slot["icon"].texture = data.icon if data != null else null
		slot["count"].text = str(int(counts.get(id, 0)))
		slot["panel"].self_modulate = FILLED
		slot["panel"].tooltip_text = data.display_name if data != null else String(id)


func close() -> void:
	if _closed:
		return
	_closed = true
	get_tree().paused = false
	closed.emit()
	queue_free()
