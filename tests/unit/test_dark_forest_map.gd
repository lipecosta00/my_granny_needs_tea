extends "res://tests/test_case.gd"
## Map integrity: spawn is walkable and every edge exit is reachable from it.
## Grows into the GDD's "todo portão é validado por script" check once
## soul gates exist.

const MAP_SCENE := "res://src/world/maps/dark_forest/dark_forest.tscn"
const GAME_SCENE := "res://src/game/game.tscn"


func _blocked(layer: TileMapLayer, cell: Vector2i) -> bool:
	var data := layer.get_cell_tile_data(cell)
	return data != null and data.get_collision_polygons_count(0) > 0


## Walkable tiles; cells under a closed gate are blocked unless its ability
## is in [param abilities] (what the player's pets can do at that point).
func _walkable_cells(map: GameMap, abilities: Array = []) -> Dictionary:
	var objects := map.actors.get_node("Objects") as TileMapLayer
	var gated := {}
	var gates := map.get_node_or_null(^"Gates")
	if gates:
		for gate: PetGate in gates.get_children():
			if gate.required_ability in abilities:
				continue
			var origin := map.ground.local_to_map(gate.position + Vector2(1, 1))
			var cells_size := Vector2i(gate.size) / map.ground.tile_set.tile_size
			for y in cells_size.y:
				for x in cells_size.x:
					gated[origin + Vector2i(x, y)] = true
	var cells := {}
	for cell in map.ground.get_used_cells():
		if not _blocked(map.ground, cell) and not _blocked(objects, cell) and not gated.has(cell):
			cells[cell] = true
	return cells


func _exits_reached(map: GameMap, abilities: Array) -> Dictionary:
	var walkable := _walkable_cells(map, abilities)
	var spawn_cell := map.ground.local_to_map(map.get_spawn_position())
	var reach := _reachable_from(spawn_cell, walkable)
	var rect := map.ground.get_used_rect()
	var exits := {"north": false, "south": false, "west": false, "east": false}
	for cell: Vector2i in reach:
		exits.north = exits.north or cell.y == rect.position.y
		exits.south = exits.south or cell.y == rect.end.y - 1
		exits.west = exits.west or cell.x == rect.position.x
		exits.east = exits.east or cell.x == rect.end.x - 1
	return exits


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


func test_spawn_is_walkable() -> void:
	var map := load(MAP_SCENE).instantiate() as GameMap
	var spawn_cell := map.ground.local_to_map(map.get_spawn_position())
	assert_true(_walkable_cells(map).has(spawn_cell), "spawn %s is blocked" % spawn_cell)
	map.free()


## GDD: "Todo portão é validado por script" — in the hub, the Bosque (west)
## needs the Vagalume's light and the cemetery (north) the Toupeira's tunnel.
func test_progression_gates() -> void:
	var map := load(MAP_SCENE).instantiate() as GameMap
	var without := _exits_reached(map, [])
	assert_true(without.south and without.east, "village and swamp are open")
	assert_false(without.west, "the bosque must require the Vagalume's light")
	assert_false(without.north, "the cemetery must require the Toupeira's tunnel")
	var everything := _exits_reached(map, [&"light", &"tunnel"])
	assert_true(everything.west and everything.north, "pets open the way")
	map.free()


func test_game_places_hero_and_pet_in_map() -> void:
	GameState.reset()
	GameState.unlock_pet(&"vagalume")
	var game := load(GAME_SCENE).instantiate() as Game
	game.use_save = false
	game.start_map = &"dark_forest"
	tree.root.add_child(game)
	assert_true(game.current_map != null, "map not loaded")
	assert_eq(game.hero.get_parent(), game.current_map.actors, "hero must live in the y-sorted layer")
	assert_vec_almost(game.hero.global_position, game.current_map.get_spawn_position())
	assert_eq(game.camera.target, game.hero)
	assert_true(game.pet is Vagalume, "active pet comes along")
	assert_eq(game.pet.get_parent(), game.current_map.actors, "pet lives with the hero")
	# queue_free + frames: an immediate free() can leave TileMapLayer
	# collision in the physics space and break later tests.
	game.queue_free()
	for i in 3:
		await tree.physics_frame
	GameState.reset()


func test_new_game_starts_at_home_without_pet() -> void:
	GameState.reset()
	var game := load(GAME_SCENE).instantiate() as Game
	game.use_save = false
	tree.root.add_child(game)
	assert_eq(game.current_map_id, &"casa")
	assert_eq(game.pet, null, "granny hands out the first pet")
	game.queue_free()
	for i in 3:
		await tree.physics_frame
