class_name GameMap
extends Node2D
## Base for every map. Maps own terrain and spawn points only; the hero and
## camera belong to Game, so they survive map transitions (and the save only
## needs the map path + entrance name).

const DEFAULT_SPAWN := &"Default"

## A MapExit was crossed (Game fades to the target map).
signal exit_requested(target_map: StringName, target_spawn: StringName)

@export var ground: TileMapLayer
## Y-sorted layer where actors (hero, souls, enemies) are placed.
@export var actors: Node2D
@export var spawns: Node2D


func _ready() -> void:
	_build_edge_walls(get_bounds())
	_spawn_enemies()
	var exits := get_node_or_null(^"Exits")
	if exits:
		for exit: MapExit in exits.get_children():
			exit.triggered.connect(func(map_id: StringName, spawn: StringName) -> void:
				exit_requested.emit(map_id, spawn))


## Markers under Spawns/Enemies carry metadata "enemy" = catalog id. Enemies
## are created fresh on every map load (re-entering repopulates the route).
func _spawn_enemies() -> void:
	var markers := spawns.get_node_or_null(^"Enemies") if spawns else null
	if markers == null:
		return
	for marker: Node2D in markers.get_children():
		for enemy in EnemyCatalog.spawn(marker.get_meta(&"enemy", &"")):
			enemy.position += marker.global_position - actors.global_position
			actors.add_child(enemy)


## Map rectangle in world pixels, from the ground layer's used cells.
func get_bounds() -> Rect2:
	if ground == null:
		return Rect2()
	var used := ground.get_used_rect()
	var tile := Vector2(ground.tile_set.tile_size)
	return Rect2(ground.position + Vector2(used.position) * tile, Vector2(used.size) * tile)


func get_spawn_position(spawn_name: StringName = DEFAULT_SPAWN) -> Vector2:
	var marker := spawns.get_node_or_null(NodePath(spawn_name)) as Node2D if spawns else null
	if marker == null:
		push_warning("%s: spawn '%s' not found, using map centre" % [name, spawn_name])
		return get_bounds().get_center()
	return marker.global_position


func _build_edge_walls(bounds: Rect2) -> void:
	var walls := StaticBody2D.new()
	walls.name = "EdgeWalls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	var t := 16.0
	var sides := [
		Rect2(bounds.position.x - t, bounds.position.y - t, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.end.y, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.position.y, t, bounds.size.y),
		Rect2(bounds.end.x, bounds.position.y, t, bounds.size.y),
	]
	for side: Rect2 in sides:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = side.size
		shape.shape = rect
		shape.position = side.get_center()
		walls.add_child(shape)
	add_child(walls)
