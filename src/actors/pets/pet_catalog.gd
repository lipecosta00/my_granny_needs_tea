class_name PetCatalog
extends RefCounted
## Pet id (GameState.active_pet, save data) -> scene. Barqueira and Toupeira
## join in Milestone 4.

const SCENES := {
	&"vagalume": preload("res://src/actors/pets/vagalume/vagalume.tscn"),
}


static func instantiate(id: StringName) -> Pet:
	var scene: PackedScene = SCENES.get(id)
	if scene == null:
		push_error("unknown pet id '%s'" % id)
		return null
	return scene.instantiate() as Pet
