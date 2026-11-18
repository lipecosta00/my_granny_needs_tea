class_name DialogueLines
extends RefCounted
## NPC lines live in code, not in scenes: Godot 4.3's export converter drops
## PackedStringArray properties with accented text when it turns .tscn into
## binary (found in playtest: Mom said nothing on the web build). Keeping text
## here also gives one place to translate (GDD: português e inglês).

const NPC := {
	&"mom": [
		"Bom dia, dorminhoco!",
		"Sua vó ligou. Disse que precisa de ajuda com um tal de \"chazinho\".",
		"A casa dela é aquela meio... assombrada, do outro lado da vila. Leva um casaco!",
	],
}


static func for_npc(id: StringName) -> Array:
	return NPC.get(id, [])
