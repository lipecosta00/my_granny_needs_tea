class_name MapCatalog
extends RefCounted
## Map id (exits, save data) -> scene path. Loaded lazily: only the current
## map is in memory.

const PATHS := {
	&"casa": "res://src/world/maps/casa/casa.tscn",
	&"vila": "res://src/world/maps/vila/vila.tscn",
	&"casa_da_vo": "res://src/world/maps/casa_da_vo/casa_da_vo.tscn",
	&"dark_forest": "res://src/world/maps/dark_forest/dark_forest.tscn",
	&"bosque": "res://src/world/maps/bosque/bosque.tscn",
	&"pantano": "res://src/world/maps/pantano/pantano.tscn",
	&"cemiterio": "res://src/world/maps/cemiterio/cemiterio.tscn",
}


static func load_scene(id: StringName) -> PackedScene:
	if not PATHS.has(id):
		push_error("unknown map '%s'" % id)
		return null
	return load(PATHS[id])
