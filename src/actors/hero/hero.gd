class_name Hero
extends CharacterBody2D
## Player character: movement, roll with i-frames, weapon swings, charged
## attack and taking damage. Every tuning number is exported (GDD: calibrar
## jogando). All timers run on [member _clock], a gameplay clock that hitstop
## freezes, so timing stays consistent under Engine.time_scale = 0.

signal facing_changed(facing: Vector2)
signal state_changed(state: State)
signal died
## RB (GDD: "Habilidade do pet"). The active pet decides combat vs exploration.
signal pet_ability_pressed
## Slots I/II changed (weapon wheel); Game mirrors it into GameState.
signal weapons_changed(primary: WeaponData, secondary: WeaponData)
## Weapon wheel opened/closed or highlight moved (-1 = none).
signal wheel_changed(open: bool, highlighted: int)

enum State { MOVE, SWING, CHARGING, DASH, SPIN, ROLL, HURT, WHEEL, DEAD }

const ATTACK_ACTIONS: Array[StringName] = [&"attack_primary", &"attack_secondary"]

@export_group("Movement")
## ~5 tiles/s at 16 px per tile.
@export var max_speed := 80.0
@export var acceleration := 1000.0
@export var friction := 1200.0

@export_group("Roll")
@export var roll_duration := 0.35
@export var roll_invulnerable_time := 0.25
@export var roll_cooldown := 0.4
@export var roll_speed := 150.0

@export_group("Combat")
@export var primary_weapon: WeaponData
@export var secondary_weapon: WeaponData
## Movement speed multiplier while holding a charge.
@export var charge_move_multiplier := 0.4
@export var input_buffer_window := 0.15
@export var hurt_stun_time := 0.2
@export var invulnerable_after_hit := 0.8
## GDD "Roda de armas": time runs at 20% while it is open.
@export var wheel_time_scale := 0.2
@export var interact_range := 18.0

## Cardinal direction the hero looks at; attacks come out this way.
var facing := Vector2.DOWN
## Cutscenes/dialogue turn this off instead of pausing the tree.
var input_enabled := true
var input: HeroInput = HeroInput.new()
var state := State.MOVE
## Weapons the wheel offers, in wheel order (set by Game from GameState).
var owned_weapons: Array[WeaponData] = []
var wheel_highlight := -1

var _clock := 0.0
var _state_time := 0.0
var _buffer: InputBuffer
var _roll_ready_at := 0.0
var _roll_dir := Vector2.DOWN
var _invulnerable_until := 0.0
var _blink_until := 0.0
var _weapon: WeaponData
var _attack_action: StringName
var _charge_started := 0.0
var _charge_ready := false
var _flash := 0.0
var _afterimage_cooldown := 0.0
var _slow_until := 0.0
var _slow_factor := 1.0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = %Sprite
@onready var _weapon_pivot: Node2D = $WeaponPivot
@onready var _weapon_sprite: Sprite2D = %WeaponSprite
@onready var _attack_hitbox: Hitbox = $AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackHitbox/Shape
@onready var _trail: Line2D = $Trail


func _ready() -> void:
	add_to_group(&"hero")
	_buffer = InputBuffer.new(input_buffer_window)
	hurtbox.hit_received.connect(_on_hit_received)
	health.depleted.connect(_on_health_depleted)
	_attack_hitbox.landed.connect(_on_attack_landed)
	_hide_weapon()


func _physics_process(delta: float) -> void:
	_clock += delta
	_state_time += delta
	_collect_buffered_input()
	match state:
		State.MOVE:
			_state_move(delta)
		State.SWING:
			_state_swing(delta)
		State.CHARGING:
			_state_charging(delta)
		State.DASH:
			_state_dash(delta)
		State.SPIN:
			_state_spin(delta)
		State.WHEEL:
			_state_wheel(delta)
		State.ROLL:
			_state_roll(delta)
		State.HURT:
			_state_hurt(delta)
		State.DEAD:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	_update_invulnerability_and_flash(delta)


# --- Public API ------------------------------------------------------------

func is_invulnerable() -> bool:
	return state == State.DEAD or _clock < _invulnerable_until


## Slime and similar hazards: speed multiplier for [param duration] seconds.
func slow(factor: float, duration: float) -> void:
	_slow_factor = factor if _clock >= _slow_until else minf(_slow_factor, factor)
	_slow_until = maxf(_slow_until, _clock + duration)


## True while the player holds the stick/keys toward [param direction]
## (doors open when you walk into them, even though the door blocks you).
func is_pushing(direction: Vector2) -> bool:
	return _move_input().dot(direction) > 0.5


func speed_multiplier() -> float:
	return _slow_factor if _clock < _slow_until else 1.0


func revive() -> void:
	health.reset()
	_cancel_attack()
	_sprite.rotation = 0.0
	_sprite.modulate = Color.WHITE
	velocity = Vector2.ZERO
	_buffer.clear()
	_invulnerable_until = _clock + 1.0
	_blink_until = _invulnerable_until
	_set_state(State.MOVE)


# --- States ----------------------------------------------------------------

func _state_move(delta: float) -> void:
	if _accepts_input() and input.is_held(&"weapon_wheel") and not owned_weapons.is_empty():
		_open_wheel()
		return
	var direction := _move_input()
	velocity = TopDownMotor.step(
		velocity, direction, max_speed * speed_multiplier(), acceleration, friction, delta)
	_update_facing(direction)
	_try_start_action()


func _try_start_action() -> bool:
	if _clock >= _roll_ready_at and _buffer.consume(&"roll", _clock):
		_start_roll()
		return true
	for action in ATTACK_ACTIONS:
		var weapon := _weapon_for(action)
		if weapon and _buffer.consume(action, _clock):
			_start_swing(weapon, action)
			return true
	return false


func _start_swing(weapon: WeaponData, action: StringName) -> void:
	_weapon = weapon
	_attack_action = action
	_charge_started = _clock
	_charge_ready = false
	_set_state(State.SWING)
	velocity *= 0.3
	_show_weapon(weapon)
	_trail.clear_points()
	if weapon.normal_kind == WeaponData.Normal.PROJECTILE:
		_fire_projectiles(weapon, 1, weapon.damage, false)
		return
	_place_attack_hitbox(facing * weapon.reach, weapon.hit_radius)
	var push := facing * weapon.knockback
	_attack_hitbox.hit_factory = func(_target: Hurtbox) -> HitData:
		return HitData.make(weapon.damage, push, HitData.Team.HERO, self)
	_attack_hitbox.active = true
	Fx.sfx(&"swing")


func _state_swing(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if _state_time < _weapon.swing_duration:
		if _weapon.normal_kind == WeaponData.Normal.SWING:
			_pose_swing(_state_time / _weapon.swing_duration)
		return
	if _weapon_pivot.visible:
		_attack_hitbox.active = false
		_hide_weapon()
	if _state_time < _weapon.swing_duration + _weapon.recovery:
		return
	if input_enabled and input.is_held(_attack_action):
		_set_state(State.CHARGING)
		_show_weapon(_weapon)
	else:
		_set_state(State.MOVE)
		_try_start_action()


func _state_charging(delta: float) -> void:
	var direction := _move_input()
	velocity = TopDownMotor.step(
		velocity, direction, max_speed * charge_move_multiplier * speed_multiplier(), acceleration, friction, delta)
	_update_facing(direction)
	_weapon_pivot.rotation = facing.angle()
	if not _charge_ready and _clock - _charge_started >= _weapon.charge_time:
		_charge_ready = true
		Fx.sfx(&"charge_ready", 0.0)
	if _clock >= _roll_ready_at and _buffer.consume(&"roll", _clock):
		_cancel_attack()
		_start_roll()
		return
	if not input_enabled or not input.is_held(_attack_action):
		if _charge_ready:
			_start_charged_attack()
		else:
			_cancel_attack()
			_set_state(State.MOVE)


func _start_charged_attack() -> void:
	match _weapon.charged_kind:
		WeaponData.Charged.SPIN:
			_start_spin()
		WeaponData.Charged.FAN:
			_fire_projectiles(_weapon, _weapon.fan_count, _weapon.charged_damage, true)
			_charge_ready = false
			_set_state(State.SWING)
			_charge_started = _clock
		_:
			_start_dash()


func _start_dash() -> void:
	_set_state(State.DASH)
	_charge_ready = false
	velocity = facing * _weapon.dash_speed
	_place_attack_hitbox(facing * 6.0, _weapon.hit_radius + 2.0)
	var weapon := _weapon
	var push := facing * weapon.charged_knockback
	_attack_hitbox.hit_factory = func(_target: Hurtbox) -> HitData:
		var hit := HitData.make(weapon.charged_damage, push, HitData.Team.HERO, self)
		hit.charged = true
		hit.wall_stun = true
		return hit
	_attack_hitbox.active = true
	Fx.sfx(&"swing", 0.0)


func _state_dash(delta: float) -> void:
	velocity = facing * _weapon.dash_speed
	_spawn_afterimage(delta)
	if _state_time >= _weapon.dash_duration:
		_cancel_attack()
		velocity *= 0.3
		_set_state(State.MOVE)
		_try_start_action()


## Axe charged: 360° around the hero (GDD: "Giro de 360°, grupos").
func _start_spin() -> void:
	_set_state(State.SPIN)
	_charge_ready = false
	velocity *= 0.2
	_place_attack_hitbox(Vector2.ZERO, _weapon.spin_radius)
	var weapon := _weapon
	_attack_hitbox.hit_factory = func(target: Hurtbox) -> HitData:
		var away := (target.global_position - global_position).normalized()
		var hit := HitData.make(weapon.charged_damage, away * weapon.charged_knockback, HitData.Team.HERO, self)
		hit.charged = true
		hit.wall_stun = true
		return hit
	_attack_hitbox.active = true
	_show_weapon(_weapon)
	_trail.clear_points()
	Fx.sfx(&"swing", 0.0)


func _state_spin(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	var t := clampf(_state_time / _weapon.spin_duration, 0.0, 1.0)
	_weapon_pivot.rotation = facing.angle() + TAU * (1.0 - pow(1.0 - t, 2.0))
	_add_trail_point()
	if _state_time >= _weapon.spin_duration:
		_cancel_attack()
		_set_state(State.MOVE)
		_try_start_action()


## Staff: one bolt (normal) or a fan (charged), out of the facing direction.
func _fire_projectiles(weapon: WeaponData, count: int, amount: int, charged: bool) -> void:
	var spread := deg_to_rad(weapon.fan_spread_degrees) if count > 1 else 0.0
	for i in count:
		var offset := 0.0 if count == 1 else lerpf(-spread / 2.0, spread / 2.0, i / float(count - 1))
		var bolt := Projectile.new()
		bolt.team = HitData.Team.HERO
		bolt.direction = facing.rotated(offset)
		bolt.speed = weapon.projectile_speed
		bolt.lifetime = weapon.projectile_lifetime
		bolt.damage = amount
		bolt.knockback = weapon.charged_knockback if charged else weapon.knockback
		bolt.color = weapon.projectile_color
		bolt.source = self
		bolt.global_position = global_position + Vector2(0, -6) + facing * 8.0
		if get_parent():
			get_parent().add_child(bolt)
	Fx.sfx(&"spark", 0.1)


# --- Weapon wheel (GDD "Roda de armas") --------------------------------------

func _open_wheel() -> void:
	_set_state(State.WHEEL)
	_buffer.clear()
	wheel_highlight = -1
	Fx.set_base_time_scale(wheel_time_scale)
	wheel_changed.emit(true, wheel_highlight)


func _state_wheel(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	var stick := input.move_vector()
	if stick.length() > 0.5:
		var index := WeaponWheel.slot_for_direction(stick, owned_weapons.size())
		if index != wheel_highlight:
			wheel_highlight = index
			wheel_changed.emit(true, wheel_highlight)
	if not input_enabled or not input.is_held(&"weapon_wheel"):
		_close_wheel()


## Presses of X/Y while the wheel is open equip instead of attacking.
func _wheel_equip(action: StringName) -> void:
	if wheel_highlight < 0 or wheel_highlight >= owned_weapons.size():
		return
	var slots := WeaponWheel.equip([primary_weapon, secondary_weapon],
		0 if action == &"attack_primary" else 1, owned_weapons[wheel_highlight])
	primary_weapon = slots[0]
	secondary_weapon = slots[1]
	Fx.sfx(&"charge_ready", 0.0)
	weapons_changed.emit(primary_weapon, secondary_weapon)


func _close_wheel() -> void:
	Fx.set_base_time_scale(1.0)
	_buffer.clear()
	_set_state(State.MOVE)
	wheel_changed.emit(false, -1)


func _try_interact() -> void:
	var probe := global_position + facing * 8.0
	var best: Node2D = null
	var best_distance := interact_range
	for node: Node2D in get_tree().get_nodes_in_group(&"interactables"):
		var d := node.global_position.distance_to(probe)
		if d <= best_distance and node.call(&"can_interact", self):
			best = node
			best_distance = d
	if best:
		best.call(&"interact", self)


func _start_roll() -> void:
	var direction := _move_input()
	_roll_dir = facing if direction.is_zero_approx() else direction.normalized()
	_update_facing(_roll_dir)
	_set_state(State.ROLL)
	_invulnerable_until = maxf(_invulnerable_until, _clock + roll_invulnerable_time)
	Fx.sfx(&"roll")


func _state_roll(delta: float) -> void:
	var t := clampf(_state_time / roll_duration, 0.0, 1.0)
	velocity = _roll_dir * roll_speed * lerpf(1.0, 0.45, t)
	var spin_sign := -1.0 if _roll_dir.x < 0.0 else 1.0
	_sprite.rotation = TAU * t * spin_sign
	_spawn_afterimage(delta)
	if _state_time >= roll_duration:
		_sprite.rotation = 0.0
		_roll_ready_at = _clock + roll_cooldown
		_set_state(State.MOVE)
		_try_start_action()


func _state_hurt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if _state_time >= hurt_stun_time:
		_set_state(State.MOVE)
		_try_start_action()


# --- Damage ----------------------------------------------------------------

func _on_hit_received(hit: HitData) -> void:
	if is_invulnerable():
		return
	health.damage(hit.damage)
	if health.is_dead():
		return
	_invulnerable_until = _clock + invulnerable_after_hit
	_blink_until = _invulnerable_until
	if state == State.WHEEL:
		_close_wheel()
	_cancel_attack()
	_sprite.rotation = 0.0
	velocity = hit.knockback
	_flash = 1.0
	_set_state(State.HURT)
	Fx.sfx(&"hurt")
	Fx.hitstop(Fx.hitstop_normal)
	Fx.shake(0.35)
	Fx.rumble(0.4, 0.6, 0.18)


func _on_health_depleted() -> void:
	if state == State.WHEEL:
		_close_wheel()
	_cancel_attack()
	_set_state(State.DEAD)
	_sprite.rotation = PI / 2.0
	_sprite.modulate = Color(0.6, 0.6, 0.7)
	Fx.sfx(&"hurt", 0.0)
	Fx.shake(0.5)
	Fx.rumble(0.6, 0.9, 0.3)
	died.emit()


func _on_attack_landed(_target: Hurtbox, hit: HitData) -> void:
	if hit.charged:
		Fx.rumble(0.3, 0.5, 0.12)


# --- Helpers ---------------------------------------------------------------

func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	state_changed.emit(state)


func _move_input() -> Vector2:
	return input.move_vector() if _accepts_input() else Vector2.ZERO


## Off during cutscenes, map changes and dialogue (and just after it).
func _accepts_input() -> bool:
	return input_enabled and not Dialogue.blocks_input()


func _unhandled_input(event: InputEvent) -> void:
	input.feed(event)


func _collect_buffered_input() -> void:
	var presses := input.take_presses()
	if not _accepts_input():
		return
	for action in presses:
		if state == State.WHEEL:
			if action in ATTACK_ACTIONS:
				_wheel_equip(action)
			continue
		match action:
			&"pet_ability":
				if state != State.DEAD:
					pet_ability_pressed.emit()
			&"interact":
				if state == State.MOVE:
					_try_interact()
			_:
				_buffer.press(action, _clock)


func _weapon_for(action: StringName) -> WeaponData:
	return primary_weapon if action == &"attack_primary" else secondary_weapon


func _update_facing(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	var new_facing := TopDownMotor.to_cardinal(direction, facing)
	if new_facing != facing:
		facing = new_facing
		facing_changed.emit(facing)
	if absf(direction.x) > 0.01:
		_sprite.flip_h = direction.x < 0.0


func _cancel_attack() -> void:
	_attack_hitbox.active = false
	_charge_ready = false
	_hide_weapon()


func _show_weapon(weapon: WeaponData) -> void:
	_weapon_sprite.region_rect = weapon.sprite_region
	_weapon_pivot.rotation = facing.angle()
	_weapon_pivot.visible = true
	# Facing up: the weapon is behind the body.
	move_child(_weapon_pivot, _visual.get_index() if facing == Vector2.UP else _visual.get_index() + 1)


func _hide_weapon() -> void:
	_weapon_pivot.visible = false
	_trail.clear_points()


## Arc from -arc/2 to +arc/2 around the facing direction, eased out.
func _pose_swing(t: float) -> void:
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var half_arc := deg_to_rad(_weapon.swing_arc_degrees) / 2.0
	_weapon_pivot.rotation = facing.angle() + lerpf(-half_arc, half_arc, eased)
	_add_trail_point()


func _add_trail_point() -> void:
	var tip := _weapon_pivot.global_position + Vector2.from_angle(_weapon_pivot.rotation) * 16.0
	_trail.add_point(tip)
	while _trail.get_point_count() > 6:
		_trail.remove_point(0)


func _place_attack_hitbox(offset: Vector2, radius: float) -> void:
	_attack_hitbox.position = Vector2(0, -6) + offset
	(_attack_shape.shape as CircleShape2D).radius = radius


func _update_invulnerability_and_flash(delta: float) -> void:
	hurtbox.invulnerable = is_invulnerable()
	var blinking := state != State.DEAD and _clock < _blink_until
	_visual.modulate.a = 0.35 if blinking and int(_clock / 0.06) % 2 == 0 else 1.0
	var glow := 0.0
	if state == State.CHARGING and _charge_ready:
		glow = 0.35 + 0.2 * sin(_clock * 20.0)
	_flash = maxf(0.0, _flash - delta * 8.0)
	(_sprite.material as ShaderMaterial).set_shader_parameter(&"flash_amount", maxf(_flash, glow))


func _spawn_afterimage(delta: float) -> void:
	_afterimage_cooldown -= delta
	if _afterimage_cooldown > 0.0 or get_parent() == null:
		return
	_afterimage_cooldown = 0.04
	var ghost := Sprite2D.new()
	ghost.texture = _sprite.texture
	ghost.region_enabled = true
	ghost.region_rect = _sprite.region_rect
	ghost.flip_h = _sprite.flip_h
	ghost.rotation = _sprite.rotation
	ghost.global_position = _sprite.global_position
	ghost.modulate = Color(0.7, 0.85, 1.0, 0.5)
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.tween_callback(ghost.queue_free)
