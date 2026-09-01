## Autoload that reads and writes the save file (Part 19).
##
## Deliberately dumb: it knows about the file, not about the farm. The level
## gathers a [SaveData] from its own nodes and hands it over, which keeps the
## save format from leaking into every script that owns state.
extends Node

## Emitted after a successful write, so the HUD can flash "Saved".
signal saved
signal loaded

const PATH := "user://savegame.tres"

## Set while loading so nodes can tell a restored value from a fresh one and skip
## their spawn effects.
var restoring: bool = false


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


## Persist [param data]. Returns true on success.
func write(data: SaveData) -> bool:
	data.version = SaveData.CURRENT_VERSION
	data.saved_at = Time.get_datetime_string_from_system(false, true)

	var error := ResourceSaver.save(data, PATH)
	if error != OK:
		push_error("Could not save to %s: %s" % [PATH, error_string(error)])
		return false

	saved.emit()
	return true


## Load the save file, or null when there is none or it is from an older build.
func read() -> SaveData:
	if not has_save():
		return null

	# CACHE_MODE_IGNORE, or a save written this session comes back stale.
	var data := ResourceLoader.load(PATH, "SaveData", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
	if data == null:
		push_warning("Save file at %s could not be read." % PATH)
		return null

	if not data.is_compatible():
		push_warning(
			(
				"Save file is version %d, this build expects %d — starting fresh."
				% [data.version, SaveData.CURRENT_VERSION]
			)
		)
		return null

	loaded.emit()
	return data


## Short description for the Continue button, empty when there is nothing to load.
func describe() -> String:
	var data := read()
	if data == null:
		return ""
	return "Day %d — %s" % [data.day, data.saved_at]


func erase() -> void:
	if not has_save():
		return
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	if error != OK:
		push_error("Could not delete %s: %s" % [PATH, error_string(error)])
