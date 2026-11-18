class_name MapExit
extends Node2D
## Rectangle (doorway or map edge) that takes the hero to another map.
## Node position = top-left; [member size] in pixels.

signal triggered(target_map: StringName, target_spawn: StringName)

@export var target_map: StringName
@export var target_spawn: StringName = &"Default"
@export var size := Vector2(16, 16)

## Ignore the hero for a moment after a map loads, so arriving never bounces.
var armed_after := 0.3
var _age := 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age < armed_after:
		return
	for hero: Node2D in get_tree().get_nodes_in_group(&"hero"):
		if Rect2(global_position, size).has_point(hero.global_position):
			triggered.emit(target_map, target_spawn)
			set_physics_process(false)
			return
