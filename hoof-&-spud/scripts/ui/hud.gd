## Everything drawn over the farm: the clock, the interact prompt, the tool bar, the
## satchel and the pause menu.
##
## Owns no game state - it reads [GameClock], [Inventory] and the player's signals,
## and forwards input to whichever panel is open. Runs in
## [constant Node.PROCESS_MODE_ALWAYS] so the pause key still works while a menu has
## the tree paused.

class_name Hud
extends CanvasLayer

## Seconds between interact-prompt polls; the prompt only changes when the player
## crosses an area edge.
const PROMPT_INTERVAL := 0.1

@onready var day_label: Label = %DayLabel
@onready var clock_label: Label = %ClockLabel
@onready var prompt_label: Label = %PromptLabel
@onready var tools_panel: Control = %ToolsPanel
@onready var inventory_panel: Control = %InventoryPanel
@onready var pause_menu: Control = %PauseMenu
@onready var toast_label: Label = %ToastLabel

var _player: Player
var _prompt_timer := 0.0
var _toast_timer := 0.0


func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player

	GameClock.time_changed.connect(_on_time_changed)
	GameClock.day_started.connect(_on_day_started)
	_update_day()
	_on_time_changed(int(GameClock.minutes))

	if _player != null:
		_player.tool_changed.connect(_on_tool_changed)
	_set_cursor()


func _process(delta: float) -> void:
	_prompt_timer -= delta
	if _prompt_timer <= 0.0:
		_prompt_timer = PROMPT_INTERVAL
		_update_prompt()

	if toast_label.visible:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_label.visible = false


## A short centred message: "You passed out", "Saved", and friends.
func toast(text: String, seconds: float = 2.6) -> void:
	toast_label.text = text
	toast_label.visible = true
	_toast_timer = seconds


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_inventory"):
		inventory_panel.set_open(not inventory_panel.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pause"):
		if _dialogue_open():
			return
		if pause_menu.is_open():
			pause_menu.close()
		else:
			pause_menu.open()
		get_viewport().set_input_as_handled()


func _on_time_changed(_minutes: int) -> void:
	# A loaded save moves the calendar without a rollover, so the day is redrawn from
	# the clock here as well as on day_started.
	clock_label.text = GameClock.clock_text()
	_update_day()


func _on_day_started(_day: int) -> void:
	_update_day()


func _update_day() -> void:
	day_label.text = "Day %d" % GameClock.day


func _update_prompt() -> void:
	if _player == null:
		return
	var target := InteractableComponent.nearest_to(_player)
	if target == null or not target.enabled:
		prompt_label.text = ""
		prompt_label.hide()
		return
	prompt_label.text = "[E]  %s" % target.prompt_text
	prompt_label.show()


func _on_tool_changed(_tool: StringName, _index: int) -> void:
	_set_cursor()


## Turns the cursor into the tool in hand, so what you are about to swing is
## visible at the pointer.
func _set_cursor() -> void:
	var data: ToolData = _player.current_tool_data() if _player != null else null
	if data != null and data.icon != null:
		# The hotspot is the third argument; the second picks which cursor shape the
		# image replaces.
		Input.set_custom_mouse_cursor(data.icon, Input.CURSOR_ARROW, Vector2(8, 8))
	else:
		Input.set_custom_mouse_cursor(null)


func _dialogue_open() -> bool:
	return not get_tree().get_nodes_in_group(&"dialogue").is_empty()
