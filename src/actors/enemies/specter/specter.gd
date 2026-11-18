class_name Specter
extends Enemy
## GDD: "Teleporta curto e ataca de perto" — teaches reading the warning.
## Vanish -> reappear ~2 tiles from the hero -> warning -> lunge -> recover.
## Invisible variant (dark corners of the cemetery): only seen inside the
## Vagalume's light; without it, it shows only at the instant of the attack.

enum Mode { DRIFT, VANISH, APPEAR, TELEGRAPH, ATTACK, RECOVER }

@export var invisible := false
## Radius of the Vagalume's light that reveals invisible specters.
@export var reveal_radius := 56.0
@export var teleport_distance := 36.0
@export var fade_time := 0.25
@export var telegraph_time := 0.5
@export var lunge_speed := 160.0
@export var lunge_time := 0.2
@export var recover_time := 0.8

var mode := Mode.DRIFT
var _mode_time := 0.0
var _lunge_dir := Vector2.DOWN
var _alpha := 1.0


func _behaviour(delta: float) -> void:
	_mode_time += delta
	var hero := find_hero(detect_radius * 1.3)
	match mode:
		Mode.DRIFT:
			velocity = Vector2.from_angle(_clock * 0.7) * 10.0
			if hero and _mode_time > 0.6:
				_set_mode(Mode.VANISH)
		Mode.VANISH:
			velocity = Vector2.ZERO
			if _mode_time >= fade_time:
				if hero:
					var side := Vector2.from_angle(randf() * TAU)
					global_position = hero.global_position + side * teleport_distance
				_set_mode(Mode.APPEAR)
		Mode.APPEAR:
			velocity = Vector2.ZERO
			if _mode_time >= fade_time:
				_set_mode(Mode.TELEGRAPH)
		Mode.TELEGRAPH:
			velocity = Vector2.ZERO
			if hero and _mode_time < telegraph_time * 0.7:
				_lunge_dir = (hero.global_position - global_position).normalized()
			if _mode_time >= telegraph_time:
				_set_mode(Mode.ATTACK)
		Mode.ATTACK:
			velocity = _lunge_dir * lunge_speed
			if _mode_time >= lunge_time:
				_set_mode(Mode.RECOVER)
		Mode.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
			if _mode_time >= recover_time:
				_set_mode(Mode.DRIFT)


## Only the lunge hurts: the warning is the whole lesson.
func can_deal_contact_damage() -> bool:
	return super() and mode == Mode.ATTACK


func is_revealed() -> bool:
	if not invisible:
		return true
	for pet: Node2D in get_tree().get_nodes_in_group(&"pets"):
		if pet.get(&"exploration_ability") == &"light" and not pet.get(&"is_out") \
				and pet.global_position.distance_to(global_position) <= reveal_radius:
			return true
	return false


## Opacity for the current state (pure; tested).
static func target_alpha(state: Mode, state_time: float, fade: float, revealed: bool) -> float:
	match state:
		Mode.VANISH:
			return (1.0 - clampf(state_time / fade, 0.0, 1.0)) * (1.0 if revealed else 0.0)
		Mode.APPEAR:
			return clampf(state_time / fade, 0.0, 1.0) * (1.0 if revealed else 0.0)
		Mode.ATTACK:
			return 1.0
		Mode.TELEGRAPH:
			return 1.0 if revealed else 0.25
	return 1.0 if revealed else 0.0


func _on_hurt() -> void:
	if mode in [Mode.TELEGRAPH, Mode.ATTACK]:
		_set_mode(Mode.RECOVER)


func _update_visuals(delta: float) -> void:
	super(delta)
	_alpha = move_toward(_alpha, target_alpha(mode, _mode_time, fade_time, is_revealed()), delta * 6.0)
	sprite.modulate.a = _alpha
	if mode == Mode.TELEGRAPH and not is_stunned():
		sprite.self_modulate = Color(1.6, 0.6, 0.6) if int(_mode_time / 0.06) % 2 == 0 else Color.WHITE


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_mode_time = 0.0
