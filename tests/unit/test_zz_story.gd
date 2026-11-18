extends "res://tests/test_case.gd"
## Story flow inside the real Game: talking, doors, granny's first gift.

const FakeInput := preload("res://tests/support/fake_hero_input.gd")


func _game(map_id: StringName) -> Game:
	var game := load("res://src/game/game.tscn").instantiate() as Game
	game.use_save = false
	game.start_map = map_id
	tree.root.add_child(game)
	game.hero.input = FakeInput.new()
	return game


func _close(game: Game) -> void:
	game.queue_free()
	for i in 3:
		await tree.physics_frame


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func _talk_through() -> void:
	for i in 30:
		if not Dialogue.active:
			return
		var press := InputEventAction.new()
		press.action = &"interact"
		press.pressed = true
		Dialogue._unhandled_input(press)
		await tree.process_frame


func test_talking_to_mom_opens_dialogue() -> void:
	GameState.reset()
	var game := _game(&"casa")
	var mom: Npc = game.current_map.actors.get_node(^"Mom")
	game.hero.global_position = mom.global_position + Vector2(-12, 0)
	game.hero.facing = Vector2.RIGHT
	await _frames(2)
	game.hero.input.tap(&"interact")
	await _frames(2)
	assert_true(Dialogue.active, "mom talks")
	await _talk_through()
	assert_false(Dialogue.active)
	await _close(game)


func test_door_takes_hero_to_the_village() -> void:
	GameState.reset()
	var game := _game(&"casa")
	var exit: MapExit = game.current_map.get_node(^"Exits").get_child(0)
	await _frames(25)  # exits arm after 0.3 s
	game.hero.global_position = exit.global_position + exit.size / 2.0
	await _frames(40)
	assert_eq(game.current_map_id, &"vila")
	assert_vec_almost(game.hero.global_position, game.current_map.get_spawn_position(&"from_casa"))
	assert_eq(GameState.current_map, &"vila", "location saved for the auto-save")
	await _close(game)


func test_granny_gives_the_vagalume_and_first_request() -> void:
	GameState.reset()
	var game := _game(&"casa_da_vo")
	var granny: Granny = game.current_map.actors.get_node(^"Granny")
	game.hero.global_position = granny.global_position + Vector2(-12, 0)
	game.hero.facing = Vector2.RIGHT
	await _frames(2)
	game.hero.input.tap(&"interact")
	await _frames(2)
	assert_true(Dialogue.active)
	await _talk_through()
	await _frames(2)
	assert_eq(GameState.quest_stage, 1)
	assert_true(game.pet is Vagalume, "granny's gift follows the hero")
	assert_eq(GameState.requested_item(), &"cogumelo")
	await _close(game)
	GameState.reset()
