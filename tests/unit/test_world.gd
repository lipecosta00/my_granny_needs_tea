extends "res://tests/test_case.gd"
## Whole-world checks across the 7 maps (GDD "Todo portão é validado por
## script, então não existe atalho que pule um pedido da vó").


func _maps() -> Dictionary:
	var maps := {}
	for id: StringName in MapCatalog.PATHS:
		maps[id] = MapCatalog.load_scene(id).instantiate()
	return maps


func _free(maps: Dictionary) -> void:
	for map: Node in maps.values():
		map.free()


func _blocked(layer: TileMapLayer, cell: Vector2i) -> bool:
	var data := layer.get_cell_tile_data(cell)
	return data != null and data.get_collision_polygons_count(0) > 0


func _cells_of(map: GameMap, origin: Vector2, size: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var first := map.ground.local_to_map(origin + Vector2(1, 1))
	var count := Vector2i(size) / map.ground.tile_set.tile_size
	for y in maxi(1, count.y):
		for x in maxi(1, count.x):
			cells.append(first + Vector2i(x, y))
	return cells


func _walkable(map: GameMap, abilities: Array) -> Dictionary:
	var objects := map.actors.get_node(^"Objects") as TileMapLayer
	var gated := {}
	var gates := map.get_node_or_null(^"Gates")
	if gates:
		for gate: PetGate in gates.get_children():
			if not gate.required_ability in abilities:
				for cell in _cells_of(map, gate.position, gate.size):
					gated[cell] = true
	var cells := {}
	for cell in map.ground.get_used_cells():
		if not _blocked(map.ground, cell) and not _blocked(objects, cell) and not gated.has(cell):
			cells[cell] = true
	return cells


func _flood(start: Vector2i, walkable: Dictionary) -> Dictionary:
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


## Explores from home through every reachable exit. Returns
## {"maps": {id: true}, "items": {item: true}, "chests": {id: true}}.
func _explore(maps: Dictionary, abilities: Array) -> Dictionary:
	var result := {"maps": {}, "items": {}, "chests": {}}
	var visited := {}
	var queue: Array = [[&"casa", &"Default"]]
	while not queue.is_empty():
		var entry: Array = queue.pop_front()
		var key := "%s/%s" % entry
		if visited.has(key):
			continue
		visited[key] = true
		var map: GameMap = maps[entry[0]]
		result.maps[entry[0]] = true
		var start := map.ground.local_to_map(map.spawns.get_node(NodePath(entry[1])).position)
		var reach := _flood(start, _walkable(map, abilities))
		var exits := map.get_node_or_null(^"Exits")
		if exits:
			for exit: MapExit in exits.get_children():
				if _cells_of(map, exit.position, exit.size).any(func(c: Vector2i) -> bool: return reach.has(c)):
					queue.append([exit.target_map, exit.target_spawn])
		for node in map.actors.get_children():
			var cell := map.ground.local_to_map(node.position)
			var near := reach.has(cell) or reach.has(cell + Vector2i.DOWN) or reach.has(cell + Vector2i.LEFT) \
				or reach.has(cell + Vector2i.RIGHT) or reach.has(cell + Vector2i.UP)
			if node is QuestItem and near:
				result.items[node.item] = true
			elif node is Chest and near:
				result.chests[node.chest_id] = true
	return result


func _pet_ability(pet_id: StringName) -> StringName:
	var pet := PetCatalog.instantiate(pet_id)
	var ability := pet.exploration_ability
	pet.free()
	return ability


func test_every_exit_leads_to_a_real_spawn() -> void:
	var maps := _maps()
	for id: StringName in maps:
		var exits: Node = maps[id].get_node_or_null(^"Exits")
		if exits == null:
			continue
		for exit: MapExit in exits.get_children():
			assert_true(maps.has(exit.target_map), "%s -> unknown map %s" % [id, exit.target_map])
			if maps.has(exit.target_map):
				var spawns: Node = maps[exit.target_map].spawns
				assert_true(spawns.has_node(NodePath(exit.target_spawn)),
					"%s -> %s has no spawn %s" % [id, exit.target_map, exit.target_spawn])
	_free(maps)


func test_spawns_are_outside_exits() -> void:
	# Arriving inside an exit would bounce the player straight back.
	var maps := _maps()
	for id: StringName in maps:
		var exits: Node = maps[id].get_node_or_null(^"Exits")
		if exits == null:
			continue
		for spawn: Node2D in maps[id].spawns.get_children():
			for exit: MapExit in exits.get_children():
				assert_false(Rect2(exit.position, exit.size).has_point(spawn.position),
					"%s: spawn %s inside exit to %s" % [id, spawn.name, exit.target_map])
	_free(maps)


func test_without_pets_only_the_safe_areas_open() -> void:
	var maps := _maps()
	var world := _explore(maps, [])
	for id in [&"casa", &"vila", &"casa_da_vo", &"dark_forest", &"pantano"]:
		assert_true(world.maps.has(id), "%s reachable on foot" % id)
	assert_false(world.maps.has(&"bosque"), "bosque needs light")
	assert_false(world.maps.has(&"cemiterio"), "cemetery needs a tunnel")
	assert_true(world.items.is_empty(), "no material without a pet, got %s" % world.items)
	_free(maps)


## Each request is doable with the pets granny has created by then, and not
## with one pet fewer.
func test_requests_follow_the_pet_order() -> void:
	var maps := _maps()
	var abilities: Array = [_pet_ability(&"vagalume")]
	for request: Dictionary in GameState.REQUESTS:
		var with_pets := _explore(maps, abilities)
		assert_true(with_pets.items.has(request.item),
			"%s reachable with %s" % [request.item, abilities])
		var fewer := abilities.slice(0, abilities.size() - 1)
		var without := _explore(maps, fewer)
		assert_false(without.items.has(request.item),
			"%s must not be reachable with only %s" % [request.item, fewer])
		if request.reward_pet != &"":
			abilities.append(_pet_ability(request.reward_pet))
	var all := _explore(maps, abilities)
	for id: StringName in MapCatalog.PATHS:
		assert_true(all.maps.has(id), "%s reachable at the end" % id)
	assert_true(all.chests.has(&"bosque/staff") and all.chests.has(&"dark_forest/secret_clearing"),
		"weapon chests reachable: %s" % all.chests)
	_free(maps)


func test_granny_conversation_plan() -> void:
	assert_eq(Granny.plan(0, &"", false).action, &"give_vagalume")
	var reminder := Granny.plan(1, &"cogumelo", false)
	assert_eq(reminder.action, &"")
	assert_true("cogumelo" in reminder.lines[0])
	assert_eq(Granny.plan(1, &"cogumelo", true).action, &"deliver")
	assert_eq(Granny.plan(4, &"", false).action, &"")


func test_delivering_creates_the_next_pet() -> void:
	GameState.reset()
	GameState.quest_stage = 1
	GameState.unlock_pet(&"vagalume")
	assert_eq(GameState.deliver_requested(), &"", "nothing to deliver yet")
	GameState.pick_up(&"bosque/cogumelo", &"cogumelo")
	assert_eq(GameState.deliver_requested(), &"barqueira")
	assert_eq(GameState.quest_stage, 2)
	assert_false(GameState.has_item(&"cogumelo"), "into the cauldron")
	assert_eq(GameState.requested_item(), &"musgo")
	assert_true(&"barqueira" in GameState.unlocked_pets)
	assert_eq(GameState.active_pet, &"vagalume", "new pet waits at the cauldron")
	GameState.reset()


func test_save_round_trip_on_disk() -> void:
	GameState.reset()
	GameState.quest_stage = 2
	GameState.unlock_pet(&"vagalume")
	GameState.unlock_pet(&"barqueira")
	GameState.current_map = &"pantano"
	GameState.current_spawn = &"from_floresta"
	var original_path := SaveSystem.path
	SaveSystem.path = "user://test_save.json"
	SaveSystem.enabled = true
	assert_eq(SaveSystem.write(GameState.to_dict()), OK)
	GameState.reset()
	GameState.from_dict(SaveSystem.read())
	assert_eq(GameState.quest_stage, 2)
	assert_eq(GameState.current_map, &"pantano")
	assert_eq(GameState.current_spawn, &"from_floresta")
	assert_true(&"barqueira" in GameState.unlocked_pets)
	SaveSystem.erase()
	SaveSystem.path = original_path
	SaveSystem.enabled = false
	GameState.reset()


func test_small_maps_are_centered_on_screen() -> void:
	var view := Vector2(480, 270)
	var interior := FollowCamera.centered_limits(Rect2(0, 0, 192, 144), view)
	assert_vec_almost(interior.get_center(), Vector2(96, 72), 0.01, "centred")
	assert_vec_almost(interior.size, view)
	var big := Rect2(0, 0, 768, 544)
	assert_eq(FollowCamera.centered_limits(big, view), big, "big maps keep their bounds")
