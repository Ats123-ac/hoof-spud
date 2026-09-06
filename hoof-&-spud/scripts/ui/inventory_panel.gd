## The satchel: a grid rendering whatever [Inventory] holds.
##
## Redraws from [signal Inventory.changed] rather than polling, and keeps a stable
## slot order - an id keeps the slot it first appeared in until it is fully removed,
## so stacks do not shuffle around while you watch them.

extends Control

const SLOT_COUNT := 24
const COLUMNS := 8
const SLOT_SIZE := Vector2(28, 28)
const ICON_SIZE := Vector2(20, 20)

const EMPTY_DIM := Color(0.62, 0.58, 0.52, 0.7)
const FILLED := Color(1.0, 1.0, 1.0, 1.0)

var _grid: GridContainer
var _slots: Array[Dictionary] = []

## Slot order: slot i holds `_order[i]`.
var _order: Array[StringName] = []


func _ready() -> void:
	visible = false

	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(box)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	box.add_child(column)

	var title := Label.new()
	title.text = "Satchel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", 4)
	_grid.add_theme_constant_override(&"v_separation", 4)
	column.add_child(_grid)

	for index in SLOT_COUNT:
		_grid.add_child(_build_slot())

	var hint := Label.new()
	hint.text = "I — close"
	hint.add_theme_font_size_override(&"font_size", 8)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)

	Inventory.changed.connect(_on_inventory_changed)


func _build_slot() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	_slots.append({"panel": panel, "icon": icon, "count": count})
	return panel


## Opens or closes; driven by the HUD's toggle.
func set_open(open: bool) -> void:
	if visible == open:
		return
	visible = open
	Audio.play(&"ui_click", 0.0)
	if open:
		_refresh_all()


func _on_inventory_changed(id: StringName, total: int) -> void:
	if not visible:
		# Keep the order list current even while closed, so reopening is correct.
		_sync_order()
		return

	if total <= 0:
		var at := _order.find(id)
		if at != -1:
			_order.remove_at(at)
	else:
		_compact_order()
		if id not in _order:
			_order.append(id)

	_refresh_all()


func _sync_order() -> void:
	var snapshot := Inventory.snapshot()
	for id in _order.duplicate():
		if int(snapshot.get(id, 0)) <= 0:
			_order.erase(id)
	for id in snapshot.keys():
		if int(snapshot[id]) > 0 and id not in _order:
			_order.append(StringName(id))


## Drops the gaps left by emptied stacks so new items fill from the left.
func _compact_order() -> void:
	var snapshot := Inventory.snapshot()
	var kept: Array[StringName] = []
	for id in _order:
		if int(snapshot.get(id, 0)) > 0:
			kept.append(id)
	_order = kept


func _refresh_all() -> void:
	_sync_order()
	var snapshot := Inventory.snapshot()

	for index in SLOT_COUNT:
		var slot: Dictionary = _slots[index]
		if index >= _order.size():
			slot["icon"].texture = null
			slot["count"].text = ""
			slot["panel"].self_modulate = EMPTY_DIM
			slot["panel"].tooltip_text = ""
			continue

		var id: StringName = _order[index]
		var data := ItemRegistry.data(id)
		var total: int = int(snapshot.get(id, 0))
		slot["icon"].texture = data.icon if data != null else null
		slot["count"].text = str(total) if total > 1 else ""
		slot["panel"].self_modulate = FILLED
		slot["panel"].tooltip_text = data.display_name if data != null else String(id)
