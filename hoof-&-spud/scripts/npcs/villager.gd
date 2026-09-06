## A person to talk to.
##
## Reuses [Animal] for the wander and idle loop - a villager is an animal that owns a
## [DialogueComponent] - and borrows the player's walk sheet facing the camera, so no
## extra art is needed. Interacting starts the conversation; only when there is
## nothing to say does it fall through to the plain greeting.

extends Animal

const SHEET := "res://Assets/farming sprites/Characters/Basic Charakter Spritesheet.png"
const CELL := Vector2i(48, 48)

@onready var dialogue: DialogueComponent = get_node_or_null(^"Dialogue")


func _ready() -> void:
	_build_frames()
	super._ready()


func _on_interacted(component: InteractableComponent) -> void:
	if dialogue != null and dialogue.start():
		return
	super._on_interacted(component)


func _build_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var sheet := load(SHEET) as Texture2D
	SpriteSheet.add_clip(frames, sheet, CELL, &"idle_down", [Vector2i(0, 0)], 1.0)
	SpriteSheet.add_clip(frames, sheet, CELL, &"walk_down", SpriteSheet.row(0, 4), 6.0)

	sprite.sprite_frames = frames
	sprite.play(&"idle_down")
