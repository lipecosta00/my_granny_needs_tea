extends "res://tests/test_case.gd"
## The six Milestone-4 enemies: each one's lesson from the GDD table.

const HERO_SCENE := preload("res://src/actors/hero/hero.tscn")
const FakeInput := preload("res://tests/support/fake_hero_input.gd")

var _world: Node2D
var _hero: Hero
var _pad: FakeInput


func _setup() -> void:
	Fx.hitstop_enabled = false
	GameState.reset()
	_world = Node2D.new()
	tree.root.add_child(_world)
	_hero = HERO_SCENE.instantiate()
	_pad = FakeInput.new()
	_hero.input = _pad
	_world.add_child(_hero)
	_hero.facing = Vector2.RIGHT


func _teardown() -> void:
	_world.free()
	Fx.hitstop_enabled = true
	GameState.reset()


func _spawn(id: StringName, at: Vector2, ai := true) -> Enemy:
	var enemy := EnemyCatalog.instantiate(id)
	enemy.position = at
	_world.add_child(enemy)
	if not ai:
		enemy.set_physics_process(false)
		enemy.contact_hitbox.active = false
	return enemy


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func test_catalog_spawns_every_id() -> void:
	for id in EnemyCatalog.SCENES:
		var spawned := EnemyCatalog.spawn(id)
		assert_eq(spawned.size(), 1, String(id))
		for e in spawned:
			e.free()
	var pack := EnemyCatalog.spawn(&"rat_pack")
	assert_eq(pack.size(), 3, "rats come in packs of 3")
	for e in pack:
		e.free()
	var ghost := EnemyCatalog.spawn(&"specter_invisible")
	assert_true(ghost[0].invisible)
	ghost[0].free()


func test_crab_shell_geometry() -> void:
	# Crab looks left; a hit pushing it right came from the left = front.
	assert_true(Crab.is_frontal(Vector2.LEFT, Vector2.RIGHT * 100.0, 60.0))
	assert_false(Crab.is_frontal(Vector2.UP, Vector2.RIGHT * 100.0, 60.0), "side")
	assert_false(Crab.is_frontal(Vector2.LEFT, Vector2.LEFT * 100.0, 60.0), "back")


func test_crab_blocks_front_but_not_flank_or_stunned() -> void:
	_setup()
	var crab: Crab = _spawn(&"crab", Vector2(16, 0), false)
	crab.facing = Vector2.LEFT  # facing the hero
	await _frames(2)
	_pad.tap(&"attack_primary")
	await _frames(16)
	assert_eq(crab.health.current, 4, "front hit bounces off the shell")
	crab.facing = Vector2.UP  # hero is now at its flank
	_pad.tap(&"attack_primary")
	await _frames(16)
	assert_eq(crab.health.current, 3, "flank hit lands")
	crab.facing = Vector2.LEFT
	crab.stun(5.0)
	_pad.tap(&"attack_primary")
	await _frames(16)
	assert_eq(crab.health.current, 1, "stunned crab can't block (and takes x2)")
	_teardown()


func test_slime_trail_slows_the_hero() -> void:
	_setup()
	var puddle := SlimePuddle.new()
	_world.add_child(puddle)
	await _frames(2)
	assert_almost(_hero.speed_multiplier(), 0.5, 0.001)
	_pad.move = Vector2.RIGHT
	await _frames(12)
	assert_true(_hero.velocity.length() <= 40.5, "half speed in slime, got %f" % _hero.velocity.length())
	_teardown()


func test_slug_leaves_puddles() -> void:
	_setup()
	_spawn(&"slug", Vector2(60, 0))
	await _frames(70)
	var puddles := _world.get_children().filter(func(n: Node) -> bool: return n is SlimePuddle)
	assert_true(puddles.size() >= 2, "trail of slime, got %d" % puddles.size())
	_teardown()


func test_invisible_specter_alpha_rules() -> void:
	var M := Specter.Mode
	assert_eq(Specter.target_alpha(M.DRIFT, 0.0, 0.25, false), 0.0, "hidden in the dark")
	assert_eq(Specter.target_alpha(M.TELEGRAPH, 0.0, 0.25, false), 0.25, "faint shimmer warns")
	assert_eq(Specter.target_alpha(M.ATTACK, 0.0, 0.25, false), 1.0, "seen when attacking")
	assert_eq(Specter.target_alpha(M.DRIFT, 0.0, 0.25, true), 1.0, "Vagalume's light reveals it")


func test_vagalume_light_reveals_invisible_specter() -> void:
	_setup()
	var ghost: Specter = _spawn(&"specter", Vector2(200, 0), false)
	ghost.invisible = true
	assert_false(ghost.is_revealed())
	var pet := PetCatalog.instantiate(&"vagalume")
	_world.add_child(pet)
	pet.global_position = Vector2(180, 0)
	assert_true(ghost.is_revealed())
	_teardown()


func test_specter_hurts_only_while_lunging() -> void:
	_setup()
	var ghost: Specter = _spawn(&"specter", Vector2(300, 300))
	await _frames(1)
	ghost._set_mode(Specter.Mode.TELEGRAPH)
	assert_false(ghost.can_deal_contact_damage())
	ghost._set_mode(Specter.Mode.ATTACK)
	assert_true(ghost.can_deal_contact_damage())
	_teardown()


func test_bat_warns_then_dives_at_hero() -> void:
	_setup()
	var bat: Bat = _spawn(&"bat", Vector2(60, 0))
	await _frames(1)
	bat._dive_dir = Vector2.LEFT
	bat._set_mode(Bat.Mode.TELEGRAPH)
	await _frames(25)
	assert_true(bat.mode in [Bat.Mode.DIVE, Bat.Mode.RETREAT], "dive follows the warning")
	assert_true(bat.global_position.x < 60.0, "moved toward the hero")
	_teardown()


func test_cyclops_hits_for_a_full_heart_and_barely_flinches() -> void:
	_setup()
	var cyclops := _spawn(&"cyclops", Vector2(6, 0))
	await _frames(8)
	assert_eq(_hero.health.current, 10, "contact = 2 (one heart)")
	assert_eq(cyclops.health.max_health, 8)
	cyclops.set_physics_process(false)
	cyclops.hurtbox.receive(HitData.make(1, Vector2(100, 0), HitData.Team.HERO))
	assert_almost(cyclops.velocity.x, 30.0, 0.01, "70% knockback resistance")
	_teardown()


func test_rats_spread_out() -> void:
	_setup()
	_hero.position = Vector2(500, 500)
	var a := _spawn(&"rat", Vector2(0, 0))
	var b := _spawn(&"rat", Vector2(1, 0))
	await _frames(20)
	assert_true(a.global_position.distance_to(b.global_position) >= 8.0, "pack keeps spacing")
	_teardown()
