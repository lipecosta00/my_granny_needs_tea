extends "res://tests/test_case.gd"
## Pure combat rules: input buffer, health, damage resolution, hearts HUD.


func test_buffer_fires_within_window() -> void:
	var buffer := InputBuffer.new(0.15)
	buffer.press(&"roll", 1.0)
	assert_true(buffer.consume(&"roll", 1.14))


func test_buffer_expires_after_window() -> void:
	var buffer := InputBuffer.new(0.15)
	buffer.press(&"roll", 1.0)
	assert_false(buffer.consume(&"roll", 1.16))


func test_buffer_consume_is_one_shot_and_peek_is_not() -> void:
	var buffer := InputBuffer.new(0.15)
	buffer.press(&"attack_primary", 0.0)
	assert_true(buffer.peek(&"attack_primary", 0.1))
	assert_true(buffer.consume(&"attack_primary", 0.1))
	assert_false(buffer.consume(&"attack_primary", 0.1))


func test_health_clamps_and_signals_depleted_once() -> void:
	var health := Health.new()
	health.max_health = 3
	health.reset()
	var deaths := [0]
	health.depleted.connect(func() -> void: deaths[0] += 1)
	assert_eq(health.damage(2), 2)
	assert_eq(health.damage(5), 1, "only remaining health is applied")
	assert_eq(health.damage(1), 0, "no damage once dead")
	assert_eq(deaths[0], 1)
	health.heal(1)
	assert_eq(health.current, 0, "dead stays dead until reset")
	health.free()


func test_heal_caps_at_max() -> void:
	var health := Health.new()
	health.max_health = 12
	health.reset()
	health.damage(3)
	health.heal(10)
	assert_eq(health.current, 12)
	health.free()


func test_stunned_target_takes_double_from_hero_only() -> void:
	var from_hero := HitData.make(3, Vector2.ZERO, HitData.Team.HERO)
	var from_enemy := HitData.make(1, Vector2.ZERO, HitData.Team.ENEMY)
	assert_eq(HitData.resolve_damage(from_hero, true), 6)
	assert_eq(HitData.resolve_damage(from_hero, false), 3)
	assert_eq(HitData.resolve_damage(from_enemy, true), 1)


func test_big_impact_needs_charged_and_stunned() -> void:
	var hit := HitData.make(3, Vector2.ZERO, HitData.Team.HERO)
	assert_false(HitData.is_big_impact(hit, true))
	hit.charged = true
	assert_false(HitData.is_big_impact(hit, false))
	assert_true(HitData.is_big_impact(hit, true))


func test_heart_states_use_half_hearts() -> void:
	assert_eq(HeartsBar.heart_states(12, 12), PackedInt32Array([2, 2, 2, 2, 2, 2]))
	assert_eq(HeartsBar.heart_states(7, 12), PackedInt32Array([2, 2, 2, 1, 0, 0]))
	assert_eq(HeartsBar.heart_states(0, 12), PackedInt32Array([0, 0, 0, 0, 0, 0]))
