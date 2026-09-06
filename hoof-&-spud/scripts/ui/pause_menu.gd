## The escape menu: resume, save, audio sliders and a way back to the title.
##
## Opening it pauses the tree; the menu runs in
## [constant Node.PROCESS_MODE_ALWAYS] so its buttons still work while paused.
## Slider changes go straight to [Audio], which persists them to
## `user://settings.cfg`.

extends Control

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var continue_button: Button = %ContinueButton
@onready var save_button: Button = %SaveButton
@onready var saved_label: Label = %SavedLabel
@onready var quit_button: Button = %QuitButton
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider

var _saved_flash := 0.0


func _ready() -> void:
	visible = false
	saved_label.visible = false

	continue_button.pressed.connect(_on_continue)
	save_button.pressed.connect(_on_save)
	quit_button.pressed.connect(_on_quit)

	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	# Reflect whatever the settings file restored at boot, without echoing it back.
	master_slider.set_block_signals(true)
	sfx_slider.set_block_signals(true)
	master_slider.value = Audio.bus_volume(Audio.BUS_MASTER) * 100.0
	sfx_slider.value = Audio.bus_volume(Audio.BUS_SFX) * 100.0
	master_slider.set_block_signals(false)
	sfx_slider.set_block_signals(false)


func _process(delta: float) -> void:
	if not saved_label.visible:
		return
	_saved_flash -= delta
	if _saved_flash <= 0.0:
		saved_label.visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	Audio.play(&"ui_click", 0.0)
	continue_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	Audio.play(&"ui_click", 0.0)


func _on_continue() -> void:
	close()


func _on_save() -> void:
	var level := get_tree().get_first_node_in_group(&"level")
	# save_now() is reached through a plain Node, so its return has no static type and
	# cannot feed a := inference.
	var ok := false
	if level != null and level.has_method(&"save_now"):
		ok = bool(level.save_now())
	saved_label.text = "Saved." if ok else "Nothing to save."
	saved_label.visible = true
	_saved_flash = 1.6
	Audio.play(&"ui_click", 0.0)


func _on_quit() -> void:
	visible = false
	get_tree().paused = false
	Audio.play(&"ui_click", 0.0)
	SceneSwap.change_scene(MENU_SCENE)


func _on_master_changed(value: float) -> void:
	Audio.set_bus_volume(Audio.BUS_MASTER, value / 100.0)


func _on_sfx_changed(value: float) -> void:
	Audio.set_bus_volume(Audio.BUS_SFX, value / 100.0)
