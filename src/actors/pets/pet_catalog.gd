class_name PetCatalog
extends RefCounted
## Pet id (GameState.active_pet, save data) -> scene.

const SCENES := {
	&"vagalume": preload("res://src/actors/pets/vagalume/vagalume.tscn"),
	&"barqueira": preload("res://src/actors/pets/barqueira/barqueira.tscn"),
	&"toupeira": preload("res://src/actors/pets/toupeira/toupeira.tscn"),
}


static func instantiate(id: StringName) -> Pet:
	var scene: PackedScene = SCENES.get(id)
	if scene == null:
		push_error("unknown pet id '%s'" % id)
		return null
	return scene.instantiate() as Pet
