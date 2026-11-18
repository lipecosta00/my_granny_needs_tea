extends "res://tests/test_case.gd"
## Barqueira and Toupeira: auto attacks, RB combat and their gates.

const HERO_SCENE := preload("res://src/actors/hero/hero.tscn")
const FakeInput := preload("res://tests/support/fake_hero_input.gd")

var _world: Node2D
var _hero: Hero
var _pad: FakeInput
var _pet: Pet


func _setup(pet_id: StringName) -> void:
	Fx.hitstop_enabled = false
	GameState.reset()
	_world = Node2D.new()
	tree.root.add_child(_world)
	_hero = HERO_SCENE.instantiate()
	_pad = FakeInput.new()
	_hero.input = _pad
	_world.add_child(_hero)
	_hero.facing = Vector2.RIGHT
	_pet = PetCatalog.instantiate(pet_id)
	_world.add_child(_pet)
	_pet.attach(_hero)


func _teardown() -> void:
	_world.free()
	Fx.hitstop_enabled = true
	GameState.reset()


func _enemy(at: Vector2, ai := false) -> Enemy:
	var enemy := EnemyCatalog.instantiate(&"spider")
	enemy.position = at
	enemy.max_health = 10
	_world.add_child(enemy)
	enemy.contact_hitbox.active = false
	if not ai:
		enemy.set(&"mode", -1)  # inert behaviour; physics still slides it
	return enemy


func _gate(ability: StringName, id: StringName) -> PetGate:
	var gate := PetGate.new()
	gate.gate_id = id
	gate.required_ability = ability
	gate.position = Vector2(20, -16)
	gate.size = Vector2(32, 32)
	_world.add_child(gate)
	return gate


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func test_cone_and_line_geometry() -> void:
	assert_true(Barqueira.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(50, 10), 80.0, 45.0))
	assert_false(Barqueira.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(-50, 0), 80.0, 45.0), "behind")
	assert_false(Barqueira.in_cone(Vector2.ZERO, Vector2.RIGHT, Vector2(120, 0), 80.0, 45.0), "too far")
	assert_true(Toupeira.in_line(Vector2.ZERO, Vector2.RIGHT, Vector2(60, 8), 80.0, 14.0))
	assert_false(Toupeira.in_line(Vector2.ZERO, Vector2.RIGHT, Vector2(60, 30), 80.0, 14.0), "off the line")


func test_barqueira_wave_pushes_and_hurts() -> void:
	_setup(&"barqueira")
	var spider := _enemy(Vector2(50, 0))
	await _frames(90)
	assert_true(spider.health.current < 10, "wave dealt damage")
	assert_true(spider.global_position.distance_to(Vector2(50, 0)) > 4.0, "and pushed it")
	_teardown()


func test_remo_pulls_cone_and_stuns() -> void:
	_setup(&"barqueira")
	var front := _enemy(Vector2(70, 0))
	var behind := _enemy(Vector2(-70, 0))
	_pet.attack_interval = 99.0  # isolate the Remo from the auto wave
	_pet._attack_timer = 99.0
	await _frames(2)
	_pet.use_ability()
	await _frames(40)
	assert_true(front.global_position.x < 40.0, "pulled toward the hero, now at %s" % front.global_position)
	assert_true(front.is_stunned() or front.global_position.x < 40.0)
	assert_almost(behind.global_position.x, -70.0, 1.0, "outside the cone")
	_teardown()


func test_remo_pulls_a_crab_out_of_its_shell() -> void:
	_setup(&"barqueira")
	var crab: Crab = EnemyCatalog.instantiate(&"crab")
	crab.position = Vector2(60, 0)
	_world.add_child(crab)
	crab.set_physics_process(false)
	crab.facing = Vector2.LEFT
	_pet.use_ability()
	assert_true(crab.is_stunned(), "stunned crabs can't block")
	_teardown()


func test_toupeira_bites_nearest_enemy() -> void:
	_setup(&"toupeira")
	var spider := _enemy(Vector2(50, 0))
	await _frames(90)
	assert_true(spider.health.current < 10)
	_teardown()


func test_tremor_stuns_a_line_in_front() -> void:
	_setup(&"toupeira")
	var in_line := _enemy(Vector2(50, 4))
	var aside := _enemy(Vector2(50, 50))
	await _frames(2)
	_pet.use_ability()
	assert_true(in_line.is_stunned())
	assert_false(aside.is_stunned())
	_teardown()


func test_each_pet_opens_only_its_own_gate() -> void:
	for pair in [[&"barqueira", &"bridge"], [&"toupeira", &"tunnel"]]:
		_setup(pair[0])
		var wrong := _gate(&"light", &"test/dark")
		var right := _gate(pair[1], StringName("test/" + String(pair[1])))
		await _frames(2)
		_pet.use_ability()
		assert_true(right.is_open, "%s opens %s" % pair)
		assert_false(wrong.is_open, "%s can't clear darkness" % pair[0])
		_teardown()


func test_vagalume_cannot_bridge() -> void:
	_setup(&"vagalume")
	var bridge := _gate(&"bridge", &"test/bridge")
	await _frames(2)
	_pet.use_ability()
	assert_false(bridge.is_open)
	assert_true(_pet.cooldown_left > 0.0, "used Clarão instead")
	_teardown()
