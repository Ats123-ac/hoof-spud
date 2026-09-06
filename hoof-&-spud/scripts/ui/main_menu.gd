## Title screen: continue an existing save, start over, or leave.
##
## The clock is stopped here so a save left open on the menu does not age; [World]
## starts it again when the farm loads.

extends Control

const WORLD_SCENE := "res://scenes/world/world.tscn"

@onready var continue_button: Button = %ContinueButton
@onready var continue_info: Label = %ContinueInfo
@onready var new_button: Button = %NewButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	GameClock.running = false

	var has_save := SaveGame.has_save()
	continue_button.disabled = not has_save
	continue_info.text = SaveGame.describe() if has_save else "No save yet."

	continue_button.pressed.connect(_on_continue)
	new_button.pressed.connect(_on_new)
	quit_button.pressed.connect(_on_quit)

	if has_save:
		continue_button.grab_focus()
	else:
		new_button.grab_focus()


func _on_continue() -> void:
	Audio.play(&"ui_click", 0.0)
	SceneSwap.change_scene(WORLD_SCENE)


func _on_new() -> void:
	Audio.play(&"ui_click", 0.0)
	SaveGame.erase()
	SceneSwap.change_scene(WORLD_SCENE)


func _on_quit() -> void:
	Audio.play(&"ui_click", 0.0)
	get_tree().quit()
