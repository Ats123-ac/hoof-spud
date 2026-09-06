## The lines its owner says through [DialogueBox], triggered by an [InteractableComponent].
##
## [member first_meeting_lines] play once per save; the speaker is then recorded in
## [member SaveGame.met] and [member lines] play from then on.

class_name DialogueComponent
extends Node

signal conversation_ended

@export var speaker: String = "???"

@export var lines: Array[String] = []

@export var first_meeting_lines: Array[String] = []

## Save key for "met"; empty falls back to [member speaker].
@export var met_key: String = ""

@export var dialogue_scene: PackedScene = preload("res://scenes/ui/dialogue_box.tscn")

## Wires itself to the [InteractableComponent] on or beside the owner, so a
## talking prop needs no glue script.
@export var hook_interactable: bool = true

var talking: bool = false


func _ready() -> void:
	if met_key.is_empty():
		met_key = speaker

	if not hook_interactable:
		return
	var host := get_parent() as InteractableComponent
	if host == null and get_parent() != null:
		host = get_parent().get_node_or_null(^"Interact") as InteractableComponent
	if host != null:
		host.interacted.connect(_on_host_interacted)


func _on_host_interacted(_component: InteractableComponent) -> void:
	start()


## False when already talking or out of lines, so callers can fall through.
func start() -> bool:
	if talking or dialogue_scene == null:
		return false
	if lines.is_empty() and first_meeting_lines.is_empty():
		return false

	talking = true
	var use_first := not first_meeting_lines.is_empty() and not SaveGame.has_met(met_key)
	if use_first:
		SaveGame.mark_met(met_key)

	var box: Node = dialogue_scene.instantiate()
	get_tree().root.add_child(box)
	var dialogue := box as DialogueBox
	dialogue.finished.connect(_on_finished.bind(use_first))
	dialogue.setup(speaker, first_meeting_lines if use_first else lines)
	return true


func _on_finished(_used_first: bool) -> void:
	talking = false
	conversation_ended.emit()
