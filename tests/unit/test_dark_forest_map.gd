extends "res://tests/test_case.gd"
## Map integrity: spawn is walkable and every edge exit is reachable from it.
## Grows into the GDD's "todo portão é validado por script" check once
## soul gates exist.

const MAP_SCENE := "res://src/world/maps/dark_forest/dark_forest.tscn"
const GAME_SCENE := "res://src/game/game.tscn"


func _blocked(layer: TileMapLayer, cell: Vector2i) -> bool:
	var data := layer.get_cell_tile_data(cell)
	return data != null and data.get_collision_polygons_count(0) > 0


func _walkable_cells(map: GameMap) -> Dictionary:
	var objects := map.actors.get_node("Objects") as TileMapLayer
	var cells := {}
	for cell in map.ground.get_used_cells():
		if not _blocked(map.ground, cell) and not _blocked(objects, cell):
			cells[cell] = true
	return cells


func _reachable_from(start: Vector2i, walkable: Dictionary) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + dir
			if walkable.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


func test_every_tile_resolves_in_tileset() -> void:
	var map := load(MAP_SCENE).instantiate() as GameMap
	for layer: TileMapLayer in [map.ground, map.actors.get_node("Objects")]:
		for cell in layer.get_used_cells():
			assert_true(layer.get_cell_tile_data(cell) != null, "%s %s has no tile" % [layer.name, cell])
	map.free()


func test_spawn_is_walkable_and_all_exits_reachable() -> void:
	var map := load(MAP_SCENE).instantiate() as GameMap
	var walkable := _walkable_cells(map)
	var spawn_cell := map.ground.local_to_map(map.get_spawn_position())
	assert_true(walkable.has(spawn_cell), "spawn %s is blocked" % spawn_cell)

	var reach := _reachable_from(spawn_cell, walkable)
	var rect := map.ground.get_used_rect()
	var exits := {"north": false, "south": false, "west": false, "east": false}
	for cell: Vector2i in reach:
		exits.north = exits.north or cell.y == rect.position.y
		exits.south = exits.south or cell.y == rect.end.y - 1
		exits.west = exits.west or cell.x == rect.position.x
		exits.east = exits.east or cell.x == rect.end.x - 1
	for side in exits:
		assert_true(exits[side], "%s exit unreachable from spawn" % side)
	map.free()


func test_game_places_hero_in_map() -> void:
	var game := load(GAME_SCENE).instantiate() as Game
	tree.root.add_child(game)
	assert_true(game.current_map != null, "map not loaded")
	assert_eq(game.hero.get_parent(), game.current_map.actors, "hero must live in the y-sorted layer")
	assert_vec_almost(game.hero.global_position, game.current_map.get_spawn_position())
	assert_eq(game.camera.target, game.hero)
	game.free()
