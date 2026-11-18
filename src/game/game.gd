class_name Game
extends Node
## Root of a play session: owns the hero and camera, loads maps into itself.
## Map transitions (Milestone 4) become: free map -> load_map(next, entrance).

@export var start_map: PackedScene
@export var hero: Hero
@export var camera: FollowCamera

var current_map: GameMap


func _ready() -> void:
	if start_map:
		load_map(start_map)


func load_map(scene: PackedScene, spawn_name: StringName = GameMap.DEFAULT_SPAWN) -> void:
	if current_map:
		hero.reparent(self, false)
		current_map.queue_free()
	current_map = scene.instantiate() as GameMap
	assert(current_map != null, "map scene root must extend GameMap")
	add_child(current_map)
	move_child(current_map, 0)
	hero.reparent(current_map.actors, false)
	hero.global_position = current_map.get_spawn_position(spawn_name)
	hero.velocity = Vector2.ZERO
	camera.target = hero
	camera.set_bounds(current_map.get_bounds())
	camera.global_position = hero.global_position
	camera.reset_smoothing()
