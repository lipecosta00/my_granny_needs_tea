extends "res://tests/test_case.gd"
## Pure pet helpers and GameState persistence.


func test_follow_point_is_behind_the_hero() -> void:
	assert_vec_almost(Pet.follow_point(Vector2(100, 100), Vector2.RIGHT, 24.0), Vector2(76, 100))
	assert_vec_almost(Pet.follow_point(Vector2.ZERO, Vector2.UP, 24.0), Vector2(0, 24))


func test_leash_keeps_pet_within_six_tiles() -> void:
	var clamped := Pet.clamp_to_leash(Vector2(300, 0), Vector2.ZERO, 96.0)
	assert_vec_almost(clamped, Vector2(96, 0))
	assert_vec_almost(Pet.clamp_to_leash(Vector2(10, 10), Vector2.ZERO, 96.0), Vector2(10, 10))


func test_pick_nearest_within_radius() -> void:
	var candidates: Array[Vector2] = [Vector2(70, 0), Vector2(30, 0), Vector2(200, 0)]
	assert_eq(Pet.pick_nearest(Vector2.ZERO, candidates, 80.0), 1)
	var far: Array[Vector2] = [Vector2(200, 0)]
	assert_eq(Pet.pick_nearest(Vector2.ZERO, far, 80.0), -1)


func test_game_state_round_trip() -> void:
	GameState.reset()
	GameState.unlock_pet(&"vagalume")
	GameState.open_gate(&"dark_forest/bosque_darkness")
	var data := GameState.to_dict()
	GameState.reset()
	assert_false(GameState.is_gate_open(&"dark_forest/bosque_darkness"))
	GameState.from_dict(data)
	assert_true(GameState.is_gate_open(&"dark_forest/bosque_darkness"))
	GameState.reset()


func test_game_state_rejects_locked_active_pet() -> void:
	GameState.from_dict({"unlocked_pets": ["vagalume"], "active_pet": "toupeira"})
	assert_eq(GameState.active_pet, &"vagalume")
	GameState.reset()
