extends "res://tests/test_case.gd"
## Regressions from playtest reports. Walk like a player, don't teleport.

const FakeInput := preload("res://tests/support/fake_hero_input.gd")


func _game(map_id: StringName, spawn: StringName = &"Default") -> Game:
	var game := load("res://src/game/game.tscn").instantiate() as Game
	game.use_save = false
	game.start_map = map_id
	tree.root.add_child(game)
	game.hero.input = FakeInput.new()
	if spawn != &"Default":
		game.load_map(map_id, spawn)
	return game


func _close(game: Game) -> void:
	game.queue_free()
	for i in 3:
		await tree.physics_frame


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func test_walk_to_mom_and_talk() -> void:
	GameState.reset()
	var game := _game(&"casa")
	var pad: FakeInput = game.hero.input
	pad.move = Vector2.RIGHT
	await _frames(90)
	pad.move = Vector2.ZERO
	var mom: Node2D = game.current_map.actors.get_node(^"Mom")
	assert_true(game.hero.global_position.distance_to(mom.global_position) < 16.0, "walked up to her")
	pad.tap(&"interact")
	await _frames(3)
	assert_true(Dialogue.active, "mom talks after walking up to her")
	while Dialogue.active:
		var e := InputEventAction.new(); e.action = &"interact"; e.pressed = true
		Dialogue._unhandled_input(e)
		await tree.process_frame
	await _close(game)


func test_cross_the_swamp_bridge() -> void:
	GameState.reset()
	GameState.quest_stage = 2
	GameState.unlock_pet(&"barqueira")
	var game := _game(&"pantano", &"from_floresta")
	var pad: FakeInput = game.hero.input
	pad.move = Vector2.RIGHT
	await _frames(150)
	game.pet.use_ability()
	await _frames(5)
	var gate: PetGate = game.current_map.get_node(^"Gates").get_child(0)
	assert_true(gate.is_open, "Barqueira's bridge")
	await _frames(120)
	assert_true(game.hero.global_position.x > 20 * 16, "crossed the canal, x=%f" % game.hero.global_position.x)
	await _close(game)


## Mom's lines must come from code: the 4.3 export converter emptied the
## PackedStringArray that used to hold them in the scene.
func test_mom_lines_are_not_stored_in_the_scene() -> void:
	var text := FileAccess.get_file_as_string("res://src/world/maps/casa/casa.tscn")
	assert_false("\nlines = " in text, "no dialogue text stored in the scene")
	assert_true("dialogue_id = &\"mom\"" in text)
	assert_true(DialogueLines.for_npc(&"mom").size() >= 2)


func test_house_door_opens_only_walking_up_into_it() -> void:
	GameState.reset()
	var game := _game(&"vila", &"from_casa")
	var pad: FakeInput = game.hero.input
	await _frames(25)
	# Walk sideways across the doorstep: must not enter.
	game.hero.global_position = Vector2(4 * 16 + 8, 9 * 16 + 14)
	pad.move = Vector2.RIGHT
	await _frames(30)
	pad.move = Vector2.ZERO
	await _frames(20)
	assert_eq(game.current_map_id, &"vila", "passing by the door doesn't enter")
	# Walk up into the door: enters.
	game.hero.global_position = Vector2(5 * 16 + 8, 10 * 16 + 10)
	pad.move = Vector2.UP
	await _frames(60)
	assert_eq(game.current_map_id, &"casa", "walking up into the door enters")
	await _close(game)


func test_house_walls_and_doors_are_solid() -> void:
	GameState.reset()
	var game := _game(&"vila", &"from_casa")
	var pad: FakeInput = game.hero.input
	await _frames(5)
	# Neighbour's house (no interior) at cells (8..10, 13..15): door (9, 15).
	game.hero.global_position = Vector2(9 * 16 + 8, 17 * 16 + 8)
	pad.move = Vector2.UP
	await _frames(60)
	assert_true(game.hero.global_position.y >= 16 * 16, "stays outside, y=%f" % game.hero.global_position.y)
	await _close(game)


func test_granny_sends_the_new_pet_along() -> void:
	GameState.reset()
	GameState.quest_stage = 1
	GameState.unlock_pet(&"vagalume")
	GameState.pick_up(&"bosque/cogumelo", &"cogumelo")
	var game := _game(&"casa_da_vo")
	var granny: Granny = game.current_map.actors.get_node(^"Granny")
	game.hero.global_position = granny.global_position + Vector2(-12, 0)
	game.hero.facing = Vector2.RIGHT
	await _frames(2)
	game.hero.input.tap(&"interact")
	await _frames(2)
	for round in 3:
		while Dialogue.active:
			var e := InputEventAction.new(); e.action = &"interact"; e.pressed = true
			Dialogue._unhandled_input(e)
			await tree.process_frame
		await _frames(3)
	assert_true(game.pet is Barqueira, "the Barqueira comes along for the swamp")
	await _close(game)
	GameState.reset()


func test_rb_a_few_tiles_from_the_canal_still_builds_the_bridge() -> void:
	GameState.reset()
	GameState.quest_stage = 2
	GameState.unlock_pet(&"barqueira")
	var game := _game(&"pantano", &"from_floresta")
	var gate: PetGate = game.current_map.get_node(^"Gates").get_child(0)
	# Three tiles short of the water, where the browser playtest pressed RB.
	game.hero.global_position = Vector2(gate.position.x - 48.0, gate.position.y + 14.0)
	await _frames(3)
	game.pet.use_ability()
	assert_true(gate.is_open, "bridge, not Remo")
	await _close(game)
	GameState.reset()
