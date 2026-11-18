extends "res://tests/test_case.gd"
## Integration: hero + Vagalume (+ dummy spiders/gates) on real physics frames.

const HERO_SCENE := preload("res://src/actors/hero/hero.tscn")
const SPIDER_SCENE := preload("res://src/actors/enemies/spider/spider.tscn")
const FakeInput := preload("res://tests/support/fake_hero_input.gd")

var _world: Node2D
var _hero: Hero
var _pet: Vagalume
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
	_pet = PetCatalog.instantiate(&"vagalume")
	_world.add_child(_pet)
	_pet.attach(_hero)


func _teardown() -> void:
	_world.free()
	GameState.reset()
	Fx.hitstop_enabled = true


func _dummy_spider(at: Vector2, hp := 10) -> Spider:
	var spider: Spider = SPIDER_SCENE.instantiate()
	spider.position = at
	spider.max_health = hp
	_world.add_child(spider)
	spider.set_physics_process(false)
	spider.contact_hitbox.active = false
	return spider


func _gate(at: Vector2, id: StringName) -> PetGate:
	var gate := PetGate.new()
	gate.gate_id = id
	gate.required_ability = &"light"
	gate.position = at
	gate.size = Vector2(32, 32)
	_world.add_child(gate)
	return gate


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func test_follows_behind_the_hero() -> void:
	_setup()
	_hero.position = Vector2(60, 0)
	_hero.facing = Vector2.RIGHT
	await _frames(60)
	var goal := Pet.follow_point(_hero.global_position, Vector2.RIGHT, _pet.follow_distance)
	assert_true(_pet.global_position.distance_to(goal) < 6.0, "pet at %s, goal %s" % [_pet.global_position, goal])
	_teardown()


func test_teleports_back_when_too_far() -> void:
	_setup()
	await _frames(2)
	_hero.position = Vector2(600, 0)
	await _frames(2)
	assert_true(_pet.global_position.distance_to(_hero.global_position) < 40.0)
	_teardown()


func test_auto_attack_hits_nearest_enemy() -> void:
	_setup()
	var near := _dummy_spider(Vector2(50, 0))
	var far := _dummy_spider(Vector2(-300, 0))
	await _frames(80)  # first spark after ~0.4 s, flight time included
	assert_true(near.health.current < 10, "nearest spider took a spark")
	assert_eq(far.health.current, 10, "out-of-range spider untouched")
	_teardown()


func test_clarao_stuns_in_radius_and_has_cooldown() -> void:
	_setup()
	await _frames(30)
	var close := _dummy_spider(_pet.global_position + Vector2(30, 0))
	var distant := _dummy_spider(_pet.global_position + Vector2(0, 120))
	var used: Array[StringName] = []
	_pet.ability_used.connect(func(kind: StringName) -> void: used.append(kind))
	_pad.tap(&"pet_ability")  # RB through the hero, like the real controller
	await _frames(2)
	assert_eq(used, [&"combat"] as Array[StringName])
	assert_true(close.is_stunned(), "spider inside 3 tiles stunned")
	assert_false(distant.is_stunned(), "spider outside 3 tiles untouched")
	assert_almost(_pet.cooldown_left, _pet.ability_cooldown, 0.1)
	_pad.tap(&"pet_ability")
	await _frames(2)
	assert_eq(used.back(), &"fizzle", "cooldown blocks a second Clarão")
	_teardown()


func test_rb_near_dark_gate_uses_luz_and_gate_stays_open() -> void:
	_setup()
	var gate := _gate(Vector2(20, -16), &"test/dark")
	await _frames(2)
	_pet.use_ability()
	assert_true(gate.is_open, "Luz cleared the darkness")
	assert_true(GameState.is_gate_open(&"test/dark"))
	assert_eq(_pet.cooldown_left, 0.0, "exploration doesn't spend the combat cooldown")
	gate.free()
	var reloaded := _gate(Vector2(20, -16), &"test/dark")  # map reloaded
	await _frames(1)
	assert_true(reloaded.is_open, "gate stays open (GameState)")
	_teardown()


func test_rb_far_from_gate_uses_clarao() -> void:
	_setup()
	var gate := _gate(Vector2(400, 400), &"test/far")
	await _frames(2)
	_pet.use_ability()
	assert_false(gate.is_open)
	assert_true(_pet.cooldown_left > 0.0, "used the combat ability instead")
	_teardown()


func test_pet_goes_out_and_comes_back() -> void:
	_setup()
	_pet.out_duration = 0.2
	var hit := HitData.make(6, Vector2.ZERO, HitData.Team.ENEMY)
	assert_true(_pet.hurtbox.receive(hit))
	assert_true(_pet.is_out, "light depleted -> apagada")
	_pet.use_ability()
	assert_eq(_pet.cooldown_left, 0.0, "no ability while out")
	await _frames(20)
	assert_false(_pet.is_out, "back after out_duration")
	assert_eq(_pet.light_bar.current, _pet.light_bar.max_health)
	_teardown()


func test_stunned_by_clarao_then_hero_hits_double() -> void:
	_setup()
	await _frames(30)
	_hero.facing = Vector2.RIGHT
	var spider := _dummy_spider(_hero.global_position + Vector2(16, 0))
	_pet.global_position = spider.global_position + Vector2(-10, 0)
	_pet.use_ability()
	assert_true(spider.is_stunned())
	var before := spider.health.current
	_pad.tap(&"attack_primary")
	await _frames(12)
	# Sparks may land too (1 each, no bonus); the sword alone deals 2.
	assert_true(before - spider.health.current >= 2, "pet stuns, hero finishes (x2)")
	_teardown()
