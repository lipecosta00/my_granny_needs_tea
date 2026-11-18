class_name EnemyCatalog
extends RefCounted
## Enemy id (as written in map spawn markers) -> scene. The JSON importer
## will emit the same ids, so maps never reference enemy scenes directly.

const SCENES := {
	&"spider": preload("res://src/actors/enemies/spider/spider.tscn"),
}


static func instantiate(id: StringName) -> Enemy:
	var scene: PackedScene = SCENES.get(id)
	if scene == null:
		push_error("unknown enemy id '%s'" % id)
		return null
	return scene.instantiate() as Enemy
