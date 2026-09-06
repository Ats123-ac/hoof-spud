## The tool bar: one slot per [ToolData] in the player's kit, the one in hand lit up.
##
## Slots are built in code from [member Player.tools] because the bar is a pure
## function of that array - adding a seventh tool in the inspector grows the bar
## without touching a scene.

extends Control

const SLOT_SIZE := Vector2(28, 28)
const ICON_SIZE := Vector2(18, 18)

const DIM := Color(0.72, 0.68, 0.62, 0.85)
const LIT := Color(1.35, 1.28, 1.0, 1.0)

var _player: Player
var _box: HBoxContainer
var _slots: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_box = HBoxContainer.new()
	_box.add_theme_constant_override(&"separation", 4)
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)

	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player == null:
		return

	for index in _player.tools.size():
		_box.add_child(_build_slot(index))
	_player.tool_changed.connect(_on_tool_changed)
	_refresh()


func _build_slot(index: int) -> Control:
	var tool: ToolData = _player.tools[index]

	var panel := Panel.new()
	panel.custom_minimum_size = SLOT_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon := TextureRect.new()
	icon.texture = tool.icon if tool != null else null
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = ICON_SIZE
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.position = Vector2(0, 1)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)

	var key := Label.new()
	key.text = str(index + 1)
	key.add_theme_font_size_override(&"font_size", 7)
	key.position = Vector2(2, 1)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(key)

	var tooltip := tool.display_name if tool != null else ""
	panel.tooltip_text = tooltip
	icon.tooltip_text = tooltip

	_slots.append({"panel": panel, "icon": icon, "key": key})
	return panel


func _on_tool_changed(_tool: StringName, _index: int) -> void:
	_refresh()


func _refresh() -> void:
	for index in _slots.size():
		var lit := _player != null and index == _player.tool_index
		_slots[index]["panel"].self_modulate = LIT if lit else DIM
