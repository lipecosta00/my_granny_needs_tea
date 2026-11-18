extends "res://tests/test_case.gd"
## Weapon wheel rules, inventory, and axe/staff/chest integration.

const HERO_SCENE := preload("res://src/actors/hero/hero.tscn")
const SPIDER_SCENE := preload("res://src/actors/enemies/spider/spider.tscn")
const FakeInput := preload("res://tests/support/fake_hero_input.gd")
const SWORD := preload("res://src/weapons/sword.tres")
const AXE := preload("res://src/weapons/axe.tres")
const STAFF := preload("res://src/weapons/staff.tres")

var _world: Node2D
var _hero: Hero
var _pad: FakeInput


func _setup(weapon: WeaponData = SWORD) -> void:
	Fx.hitstop_enabled = false
	GameState.reset()
	_world = Node2D.new()
	tree.root.add_child(_world)
	_hero = HERO_SCENE.instantiate()
	_pad = FakeInput.new()
	_hero.input = _pad
	_world.add_child(_hero)
	_hero.primary_weapon = weapon
	_hero.facing = Vector2.RIGHT


func _teardown() -> void:
	_world.free()
	Engine.time_scale = 1.0
	Fx.base_time_scale = 1.0
	Fx.hitstop_enabled = true
	GameState.reset()


func _dummy_spider(at: Vector2, hp := 10) -> Spider:
	var spider: Spider = SPIDER_SCENE.instantiate()
	spider.position = at
	spider.max_health = hp
	_world.add_child(spider)
	spider.set_physics_process(false)
	spider.contact_hitbox.active = false
	return spider


func _frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


# --- Pure rules ----------------------------------------------------------------

func test_wheel_slot_from_stick() -> void:
	assert_eq(WeaponWheel.slot_for_direction(Vector2.UP, 3), 0)
	assert_eq(WeaponWheel.slot_for_direction(Vector2(0.87, 0.5), 3), 1)
	assert_eq(WeaponWheel.slot_for_direction(Vector2(-0.87, 0.5), 3), 2)
	assert_eq(WeaponWheel.slot_for_direction(Vector2.ZERO, 3), -1)


func test_equip_swaps_instead_of_duplicating() -> void:
	assert_eq(WeaponWheel.equip([SWORD, AXE], 0, AXE), [AXE, SWORD])
	assert_eq(WeaponWheel.equip([SWORD, null], 1, STAFF), [SWORD, STAFF])


func test_new_weapon_fills_empty_slot_and_round_trips() -> void:
	GameState.reset()
	GameState.give_weapon(&"axe")
	assert_eq(GameState.equipped_weapons, [&"sword", &"axe"] as Array[StringName])
	var data := GameState.to_dict()
	GameState.reset()
	GameState.from_dict(data)
	assert_true(&"axe" in GameState.owned_weapons)
	assert_eq(GameState.equipped_weapons[1], &"axe")
	GameState.reset()


# --- Integration -----------------------------------------------------------------

func test_axe_swing_deals_two() -> void:
	_setup(AXE)
	var spider := _dummy_spider(Vector2(16, 0))
	await _frames(2)
	_pad.tap(&"attack_primary")
	await _frames(20)
	assert_eq(spider.health.current, 8)
	_teardown()


func test_axe_charged_spin_hits_all_around() -> void:
	_setup(AXE)
	var right := _dummy_spider(Vector2(16, 0))
	var left := _dummy_spider(Vector2(-16, 0))
	await _frames(2)
	_pad.hold(&"attack_primary")
	await _frames(45)  # swing (and its hit on the right one) + full charge
	_pad.release(&"attack_primary")
	await _frames(30)
	assert_eq(left.health.current, 7, "spin reaches behind the hero for 3")
	assert_true(right.health.current <= 7, "and in front")
	_teardown()


func test_staff_bolt_hits_at_range_for_one() -> void:
	_setup(STAFF)
	var spider := _dummy_spider(Vector2(80, 0))
	await _frames(2)
	_pad.tap(&"attack_primary")
	await _frames(40)
	assert_eq(spider.health.current, 9)
	_teardown()


func test_staff_bolt_stops_at_walls() -> void:
	_setup(STAFF)
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(8, 64)
	wall.add_child(shape)
	wall.position = Vector2(40, 0)
	_world.add_child(wall)
	var spider := _dummy_spider(Vector2(80, 0))
	await _frames(2)
	_pad.tap(&"attack_primary")
	await _frames(40)
	assert_eq(spider.health.current, 10, "tree/wall absorbs the bolt")
	_teardown()


func test_staff_charged_fires_a_fan_of_three() -> void:
	_setup(STAFF)
	await _frames(2)
	_pad.hold(&"attack_primary")
	await _frames(45)
	_pad.release(&"attack_primary")
	await _frames(2)
	var bolts := _world.get_children().filter(func(n: Node) -> bool: return n is Projectile)
	assert_eq(bolts.size(), 3)
	_teardown()


func test_wheel_slows_time_and_equips_with_x_y() -> void:
	_setup(SWORD)
	_hero.owned_weapons = [SWORD, AXE, STAFF]
	await _frames(2)
	_pad.held[&"weapon_wheel"] = true
	await _frames(2)
	assert_eq(_hero.state, Hero.State.WHEEL)
	assert_almost(Engine.time_scale, 0.2, 0.001, "time at 20% while open")
	_pad.move = Vector2(0.87, 0.5)  # toward the axe
	await _frames(2)
	_pad.tap(&"attack_secondary")
	await _frames(2)
	assert_eq(_hero.secondary_weapon, AXE, "Y equips the highlighted weapon in slot II")
	assert_eq(_hero.state, Hero.State.WHEEL, "equipping doesn't attack")
	_pad.move = Vector2.ZERO
	_pad.held.erase(&"weapon_wheel")
	await _frames(2)
	assert_eq(_hero.state, Hero.State.MOVE)
	assert_eq(Engine.time_scale, 1.0, "time back to normal")
	_teardown()


func test_chest_gives_weapon_and_stays_open() -> void:
	_setup(SWORD)
	var chest := Chest.new()
	chest.chest_id = &"test/chest"
	chest.item = &"staff"
	chest.position = Vector2(10, 0)
	_world.add_child(chest)
	await _frames(2)
	_pad.tap(&"interact")
	await _frames(2)
	assert_true(chest.is_open)
	assert_true(&"staff" in GameState.owned_weapons)
	chest.free()
	var again := Chest.new()
	again.chest_id = &"test/chest"
	_world.add_child(again)
	assert_true(again.is_open, "opened chests stay open")
	_teardown()
