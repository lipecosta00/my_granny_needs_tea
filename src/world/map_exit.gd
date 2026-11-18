class_name MapExit
extends Node2D
## Rectangle (doorway or map edge) that takes the hero to another map.
## Node position = top-left; [member size] in pixels.

signal triggered(target_map: StringName, target_spawn: StringName)

@export var target_map: StringName
@export var target_spawn: StringName = &"Default"
@export var size := Vector2(16, 16)
## Doors: only trigger while the hero walks this way (ZERO = any direction).
@export var required_facing := Vector2.ZERO

## Ignore the hero for a moment after a map loads, so arriving never bounces.
var armed_after := 0.3
var _age := 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age < armed_after:
		return
	for hero: Node2D in get_tree().get_nodes_in_group(&"hero"):
		var facing_ok: bool = required_facing == Vector2.ZERO \
			or (hero.get(&"facing") == required_facing and hero.get(&"velocity").dot(required_facing) >= 0.0 \
				and hero.call(&"is_pushing", required_facing))
		if facing_ok and Rect2(global_position, size).has_point(hero.global_position):
			triggered.emit(target_map, target_spawn)
			set_physics_process(false)
			return
