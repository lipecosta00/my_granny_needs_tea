class_name EnemyCatalog
extends RefCounted
## Enemy id (as written in map spawn markers) -> scene(s). The JSON importer
## will emit the same ids, so maps never reference enemy scenes directly.

const SCENES := {
	&"spider": preload("res://src/actors/enemies/spider/spider.tscn"),
	&"bat": preload("res://src/actors/enemies/bat/bat.tscn"),
	&"rat": preload("res://src/actors/enemies/rat/rat.tscn"),
	&"slug": preload("res://src/actors/enemies/slug/slug.tscn"),
	&"crab": preload("res://src/actors/enemies/crab/crab.tscn"),
	&"specter": preload("res://src/actors/enemies/specter/specter.tscn"),
	&"cyclops": preload("res://src/actors/enemies/cyclops/cyclops.tscn"),
}
## Group spawns: id -> [member id, count]. GDD: rats come in packs of 3.
const GROUPS := {
	&"rat_pack": [&"rat", 3],
}


static func instantiate(id: StringName) -> Enemy:
	var scene: PackedScene = SCENES.get(id)
	if scene == null:
		push_error("unknown enemy id '%s'" % id)
		return null
	return scene.instantiate() as Enemy


## Everything one spawn marker creates, with offsets from the marker.
## "specter_invisible" is the dark-corner variant (GDD "Variante").
static func spawn(id: StringName) -> Array[Enemy]:
	var result: Array[Enemy] = []
	if GROUPS.has(id):
		var member: StringName = GROUPS[id][0]
		var count: int = GROUPS[id][1]
		for i in count:
			var enemy := instantiate(member)
			enemy.position = Vector2.from_angle(TAU * i / count) * 10.0
			result.append(enemy)
	elif id == &"specter_invisible":
		var specter := instantiate(&"specter")
		specter.set(&"invisible", true)
		result.append(specter)
	else:
		var enemy := instantiate(id)
		if enemy:
			result.append(enemy)
	return result
