extends "res://tests/test_case.gd"
## Integration: real hero/spider scenes on real physics frames (1/60 s each),
## driven by a scripted controller. Hitstop is off so frame counts = time.

const HERO_SCENE := preload("res://src/actors/hero/hero.tscn")
const SPIDER_SCENE := preload("res://src/actors/enemies/spider/spider.tscn")


const FakeInput := preload("res://tests/support/fake_hero_input.gd")


var _world: Node2D
var _hero: Hero
var _pad: FakeInput


func _setup() -> void:
	Fx.hitstop_enabled = false
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


## Spider that stands still (AI off) so only the hero's attacks matter.
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


func test_tap_shorter_than_a_frame_still_attacks() -> void:
	_setup()
	_hero.input = HeroInput.new()  # real event path
	var press := InputEventAction.new()
	press.action = &"attack_primary"
	press.pressed = true
	var release := InputEventAction.new()
	release.action = &"attack_primary"
	release.pressed = false
	_hero._unhandled_input(press)
	_hero._unhandled_input(release)
	await _frames(2)
	assert_eq(_hero.state, Hero.State.SWING)
	_teardown()


func test_roll_has_iframes_then_becomes_vulnerable() -> void:
	_setup()
	_pad.tap(&"roll")
	await _frames(2)
	assert_eq(_hero.state, Hero.State.ROLL)
	assert_true(_hero.hurtbox.invulnerable, "invulnerable at roll start")
	await _frames(15)  # ~0.28 s: past the 0.25 s i-frames, still rolling
	assert_eq(_hero.state, Hero.State.ROLL)
	assert_false(_hero.hurtbox.invulnerable, "vulnerable after i-frames")
	_teardown()


func test_roll_has_cooldown() -> void:
	_setup()
	_pad.tap(&"roll")
	await _frames(24)  # roll done (0.35 s)
	assert_eq(_hero.state, Hero.State.MOVE)
	_pad.tap(&"roll")
	await _frames(2)
	assert_eq(_hero.state, Hero.State.MOVE, "cooldown blocks an immediate second roll")
	_teardown()


func test_attack_pressed_late_in_roll_is_buffered() -> void:
	_setup()
	_pad.tap(&"roll")
	await _frames(14)  # ~0.1 s before the roll ends
	_pad.tap(&"attack_primary")
	await _frames(10)
	assert_eq(_hero.state, Hero.State.SWING, "buffered attack fires when the roll ends")
	_teardown()


func test_attack_pressed_too_early_is_dropped() -> void:
	_setup()
	_pad.tap(&"roll")
	await _frames(3)  # ~0.3 s before the roll ends: outside the 0.15 s buffer
	_pad.tap(&"attack_primary")
	await _frames(25)
	assert_eq(_hero.state, Hero.State.MOVE)
	_teardown()


func test_sword_swing_hits_once_per_swing() -> void:
	_setup()
	var spider := _dummy_spider(Vector2(16, 0))
	await _frames(2)
	_pad.tap(&"attack_primary")
	await _frames(14)
	assert_eq(spider.health.current, 9, "one swing = 1 damage, not once per frame")
	_teardown()


func test_two_swings_kill_a_spider() -> void:
	_setup()
	var spider := _dummy_spider(Vector2(16, 0), 2)
	var deaths := [0]
	spider.died.connect(func(_e: Enemy) -> void: deaths[0] += 1)
	await _frames(2)
	_pad.tap(&"attack_primary")
	await _frames(16)
	_pad.tap(&"attack_primary")
	await _frames(16)
	assert_eq(deaths[0], 1)
	_teardown()


func test_stunned_enemy_takes_double() -> void:
	_setup()
	var spider := _dummy_spider(Vector2(16, 0))
	spider.stun(5.0)
	await _frames(2)
	_pad.tap(&"attack_primary")
	await _frames(14)
	assert_eq(spider.health.current, 8)
	_teardown()


func test_hold_charges_and_release_dashes_for_three() -> void:
	_setup()
	var spider := _dummy_spider(Vector2(34, 0))
	await _frames(2)
	_pad.hold(&"attack_primary")
	await _frames(20)
	assert_eq(_hero.state, Hero.State.CHARGING)
	await _frames(24)  # > 0.6 s since the press
	_pad.release(&"attack_primary")
	await _frames(2)
	assert_eq(_hero.state, Hero.State.DASH)
	await _frames(12)
	assert_eq(spider.health.current, 7, "charged dash deals 3")
	_teardown()


func test_short_hold_does_not_dash() -> void:
	_setup()
	_pad.hold(&"attack_primary")
	await _frames(20)
	_pad.release(&"attack_primary")
	await _frames(3)
	assert_eq(_hero.state, Hero.State.MOVE)
	_teardown()


func test_taking_damage_knocks_back_and_grants_iframes() -> void:
	_setup()
	await _frames(1)
	var hit := HitData.make(1, Vector2(120, 0), HitData.Team.ENEMY)
	assert_true(_hero.hurtbox.receive(hit))
	assert_eq(_hero.health.current, 11, "half a heart")
	assert_eq(_hero.state, Hero.State.HURT)
	await _frames(2)
	assert_true(_hero.velocity.x > 0.0, "knocked back")
	assert_false(_hero.hurtbox.receive(HitData.make(1, Vector2.ZERO, HitData.Team.ENEMY)))
	assert_eq(_hero.health.current, 11, "i-frames block the second hit")
	await _frames(50)  # > 0.8 s
	assert_true(_hero.hurtbox.receive(HitData.make(1, Vector2.ZERO, HitData.Team.ENEMY)))
	assert_eq(_hero.health.current, 10)
	_teardown()


func test_spider_telegraphs_then_dashes_at_hero() -> void:
	_setup()
	var spider: Spider = SPIDER_SCENE.instantiate()
	spider.position = Vector2(60, 0)
	_world.add_child(spider)
	await _frames(3)
	assert_eq(spider.mode, Spider.Mode.TELEGRAPH, "hero in range triggers the warning")
	await _frames(36)  # telegraph 0.55 s
	assert_eq(spider.mode, Spider.Mode.DASH)
	assert_true(spider.velocity.x < 0.0, "dashes toward the hero")
	_teardown()


func test_spider_dash_into_wall_stuns() -> void:
	_setup()
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(16, 64)
	wall.add_child(shape)
	wall.position = Vector2(-40, 0)
	_world.add_child(wall)
	_hero.position = Vector2(400, 400)  # out of reach: drive the dash by hand
	var spider: Spider = SPIDER_SCENE.instantiate()
	spider.position = Vector2(0, 0)
	_world.add_child(spider)
	await _frames(1)
	spider._dash_dir = Vector2.LEFT
	spider._set_mode(Spider.Mode.DASH)
	await _frames(15)
	assert_true(spider.is_stunned(), "dash into a wall stuns")
	_teardown()


func test_spider_dash_into_hero_does_not_stun_or_overlap() -> void:
	_setup()
	_hero.position = Vector2(40, 0)
	var spider: Spider = SPIDER_SCENE.instantiate()
	_world.add_child(spider)
	await _frames(1)
	spider._dash_dir = Vector2.RIGHT
	spider._set_mode(Spider.Mode.DASH)
	await _frames(15)
	assert_false(spider.is_stunned(), "bumping the hero is not a wall")
	assert_true(_hero.health.current < 12, "the dash still hurts")
	assert_true(spider.global_position.distance_to(_hero.global_position) >= 6.0, "bodies don't stack")
	_teardown()
