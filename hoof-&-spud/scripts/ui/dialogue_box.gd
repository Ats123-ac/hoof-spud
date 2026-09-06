## A speech balloon: typewritten lines, advanced with the interact key, a click or
## space.
##
## Opening one pauses the tree so the conversation owns the player's attention; the
## box runs in [constant Node.PROCESS_MODE_ALWAYS] to stay clickable while paused.
## [signal finished] tells the [DialogueComponent] that spawned it to mark the
## speaker as met and let go.

class_name DialogueBox
extends CanvasLayer

signal finished

## Characters revealed per second.
const TYPE_SPEED := 45.0

@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel
@onready var hint_label: Label = %HintLabel

var _lines: Array[String] = []
var _line_index := -1
var _revealed := 0.0
var _full := ""
var _closed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"dialogue")
	hint_label.visible = false
	get_tree().paused = true


## Called by [DialogueComponent] right after the node enters the tree.
func setup(speaker: String, lines: Array[String]) -> void:
	name_label.text = speaker
	_lines = lines.duplicate()
	_next_line()


func _process(delta: float) -> void:
	if _revealed >= float(_full.length()):
		return
	_revealed = minf(_revealed + delta * TYPE_SPEED, float(_full.length()))
	text_label.text = _full.substr(0, int(_revealed))
	hint_label.visible = _revealed >= float(_full.length())


func _unhandled_input(event: InputEvent) -> void:
	var advance := (
		event.is_action_pressed(&"interact")
		or event.is_action_pressed(&"use_tool")
		or event.is_action_pressed(&"ui_accept")
	)
	if not advance:
		return
	get_viewport().set_input_as_handled()

	if _revealed < float(_full.length()):
		# Finish the line rather than skipping past it.
		_revealed = float(_full.length())
		text_label.text = _full
		hint_label.visible = true
		Audio.play(&"ui_click", 0.0)
		return

	Audio.play(&"ui_click", 0.0)
	_next_line()


func _next_line() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_close()
		return
	_full = _lines[_line_index]
	_revealed = 0.0
	text_label.text = ""
	hint_label.visible = false


func _close() -> void:
	if _closed:
		return
	_closed = true
	get_tree().paused = false
	finished.emit()
	queue_free()
