class_name PetCatalog
extends RefCounted
## Pet id (GameState.active_pet, save data) -> scene.

const SCENES := {
	&"vagalume": preload("res://src/actors/pets/vagalume/vagalume.tscn"),
	&"barqueira": preload("res://src/actors/pets/barqueira/barqueira.tscn"),
	&"toupeira": preload("res://src/actors/pets/toupeira/toupeira.tscn"),
}


## Text for the cauldron's pet screen (GDD "Pets").
const INFO := {
	&"vagalume": {
		"name": "Vagalume", "color": Color(1, 0.88, 0.35),
		"combat": "Clarão: atordoa quem está perto.",
		"explore": "Luz: dissipa a escuridão.",
	},
	&"barqueira": {
		"name": "Barqueira", "color": Color(0.45, 0.72, 1),
		"combat": "Remo: puxa inimigos à frente.",
		"explore": "Ponte: atravessa o canal.",
	},
	&"toupeira": {
		"name": "Toupeira", "color": Color(0.58, 0.78, 0.36),
		"combat": "Tremor: atordoa em linha.",
		"explore": "Túnel: passa sob grades.",
	},
}


static func instantiate(id: StringName) -> Pet:
	var scene: PackedScene = SCENES.get(id)
	if scene == null:
		push_error("unknown pet id '%s'" % id)
		return null
	return scene.instantiate() as Pet
