## Autoload that reads and writes the single save file.
##
## Knows the file, not the farm: the level gathers a [SaveData] from its own nodes
## and hands it over, which keeps the format out of every script that owns state.

extends Node

signal saved
signal loaded

const PATH := "user://savegame.tres"

## Set while loading so nodes can tell a restored value from a fresh one.
var restoring: bool = false

## Live mirror of [member SaveData.met]; copied in on write and back out on read.
var met: Array[String] = []


func has_met(key: String) -> bool:
	return key in met


func mark_met(key: String) -> void:
	if key not in met:
		met.append(key)


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func write(data: SaveData) -> bool:
	data.version = SaveData.CURRENT_VERSION
	data.saved_at = Time.get_datetime_string_from_system(false, true)

	var error := ResourceSaver.save(data, PATH)
	if error != OK:
		push_error("Could not save to %s: %s" % [PATH, error_string(error)])
		return false

	saved.emit()
	return true


func read() -> SaveData:
	if not has_save():
		return null

	# CACHE_MODE_IGNORE, or a save written this session reads back stale.
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


## One-line summary for the Continue button; empty when there is no save.
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
