extends Node
## Auto-save on map change (GDD "Salvamento"). JSON in user://, which the web
## build stores in IndexedDB (clearing site data deletes it).

## A var (not const) so tests can point it at a scratch file.
var path := "user://save.json"

## Tests turn this off so they never touch the player's save.
var enabled := true


func has_save() -> bool:
	return enabled and FileAccess.file_exists(path)


func write(data: Dictionary) -> Error:
	if not enabled:
		return OK
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	return OK


func read() -> Dictionary:
	if not has_save():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
