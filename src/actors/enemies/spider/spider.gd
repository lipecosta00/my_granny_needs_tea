class_name Spider
extends Enemy
## GDD: "Avança em linha reta depois de um aviso" — teaches rolling on time.
## Wander -> telegraph (aim tracks, then locks) -> straight dash -> recover.
## A dash that ends in a wall stuns the spider: dodge well, punish double.

enum Mode { WANDER, TELEGRAPH, DASH, RECOVER }

@export var wander_speed := 22.0
@export var telegraph_time := 0.55
## Aim stops tracking this long before the dash, so a well-timed roll dodges.
@export var aim_lock_time := 0.18
@export var dash_speed := 210.0
@export var dash_time := 0.45
@export var recover_time := 0.7
@export var dash_wall_stun_time := 1.0

var mode := Mode.WANDER
var _mode_time := 0.0
var _dash_dir := Vector2.RIGHT
var _wander_dir := Vector2.ZERO
var _next_wander_change := 0.0


func _behaviour(delta: float) -> void:
	_mode_time += delta
	match mode:
		Mode.WANDER:
			var hero := find_hero(detect_radius)
			if hero:
				_aim_at(hero)
				_set_mode(Mode.TELEGRAPH)
				Fx.sfx(&"spider_warn")
				velocity = Vector2.ZERO
				return
			if _clock >= _next_wander_change:
				_next_wander_change = _clock + randf_range(0.8, 1.8)
				_wander_dir = Vector2.ZERO if randf() < 0.3 else Vector2.from_angle(randf() * TAU)
			velocity = _wander_dir * wander_speed
		Mode.TELEGRAPH:
			velocity = Vector2.ZERO
			if _mode_time < telegraph_time - aim_lock_time:
				var hero := find_hero(detect_radius * 1.5)
				if hero:
					_aim_at(hero)
			if _mode_time >= telegraph_time:
				_set_mode(Mode.DASH)
		Mode.DASH:
			velocity = _dash_dir * dash_speed
			if _mode_time >= dash_time:
				_set_mode(Mode.RECOVER)
		Mode.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
			if _mode_time >= recover_time:
				_set_mode(Mode.WANDER)


func _after_move(_delta: float) -> void:
	if get_slide_collision_count() == 0:
		return
	if mode == Mode.DASH:
		velocity = Vector2.ZERO
		_set_mode(Mode.RECOVER)
		if hit_world():
			# Dodged into a tree: stunned, punish for double damage.
			stun(dash_wall_stun_time)
			Fx.shake(0.2)
			Fx.sfx(&"hit")
	elif mode == Mode.WANDER:
		_wander_dir = -_wander_dir


func _on_hurt() -> void:
	if mode in [Mode.TELEGRAPH, Mode.DASH]:
		_set_mode(Mode.RECOVER)


func _update_visuals(delta: float) -> void:
	super(delta)
	# Telegraph: red pulse + jitter, so the warning reads at a glance.
	if mode == Mode.TELEGRAPH and not is_stunned():
		var pulse := int(_mode_time / 0.06) % 2 == 0
		sprite.self_modulate = Color(1.6, 0.6, 0.6) if pulse else Color(1.2, 0.9, 0.9)
		sprite.position.x = 1.0 if pulse else -1.0
	else:
		sprite.position.x = 0.0


func _aim_at(target: Node2D) -> void:
	var to_target := target.global_position - global_position
	if not to_target.is_zero_approx():
		_dash_dir = to_target.normalized()


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_mode_time = 0.0
