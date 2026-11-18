class_name Enemy
extends CharacterBody2D
## Shared enemy plumbing: health, hurt/knockback, stun (double damage), wall
## stun, contact damage and hit feedback. Subclasses only implement
## _behaviour() — the per-enemy state machine from the GDD table.

signal died(enemy: Enemy)

@export var max_health := 2
## In half-hearts (GDD: a common hit takes half a heart).
@export var contact_damage := 1
@export var contact_knockback := 150.0
@export var knockback_friction := 900.0
@export var hurt_time := 0.18
@export var wall_stun_time := 1.0
@export var wall_stun_min_speed := 100.0
@export var detect_radius := 96.0
@export var hit_particle_color := Color(0.85, 0.85, 0.9)

var stunned_for := 0.0
var _hurt_for := 0.0
var _wall_stun_armed := false
var _flash := 0.0
var _clock := 0.0
var _dead := false

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var contact_hitbox: Hitbox = $ContactHitbox
@onready var sprite: Sprite2D = %Sprite


func _ready() -> void:
	add_to_group(&"enemies")
	health.max_health = max_health
	health.reset()
	hurtbox.hit_received.connect(_on_hit_received)
	health.depleted.connect(_die)
	contact_hitbox.hit_factory = _make_contact_hit


func _physics_process(delta: float) -> void:
	_clock += delta
	stunned_for = maxf(0.0, stunned_for - delta)
	_hurt_for = maxf(0.0, _hurt_for - delta)
	if _hurt_for > 0.0 or stunned_for > 0.0:
		var speed_before := velocity.length()
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		if _wall_stun_armed and hit_world() and speed_before >= wall_stun_min_speed:
			_wall_stun_armed = false
			stun(wall_stun_time)
	else:
		_wall_stun_armed = false
		_behaviour(delta)
		move_and_slide()
		_after_move(delta)
	contact_hitbox.active = can_deal_contact_damage()
	_update_visuals(delta)


# --- Public API ------------------------------------------------------------

func is_stunned() -> bool:
	return stunned_for > 0.0


func stun(duration: float) -> void:
	stunned_for = maxf(stunned_for, duration)
	_on_stunned()


func can_deal_contact_damage() -> bool:
	return not _dead and not is_stunned() and _hurt_for <= 0.0


## True if the last move_and_slide hit level geometry (tiles, walls), not a
## character: bumping into the hero or another enemy is not a "wall".
func hit_world() -> bool:
	for i in get_slide_collision_count():
		if not (get_slide_collision(i).get_collider() is CharacterBody2D):
			return true
	return false


## Closest hero within [param radius], or null.
func find_hero(radius: float) -> Node2D:
	for hero: Node2D in get_tree().get_nodes_in_group(&"hero"):
		if hero is Hero and hero.state == Hero.State.DEAD:
			continue
		if global_position.distance_to(hero.global_position) <= radius:
			return hero
	return null


# --- Hooks for subclasses ----------------------------------------------------

func _behaviour(_delta: float) -> void:
	pass


func _after_move(_delta: float) -> void:
	pass


func _on_hurt() -> void:
	pass


func _on_stunned() -> void:
	pass


# --- Internals -------------------------------------------------------------

func _make_contact_hit(target: Hurtbox) -> HitData:
	var away := (target.global_position - global_position).normalized()
	return HitData.make(contact_damage, away * contact_knockback, HitData.Team.ENEMY, self)


func _on_hit_received(hit: HitData) -> void:
	if _dead:
		return
	var was_stunned := is_stunned()
	var amount := HitData.resolve_damage(hit, was_stunned)
	var big := HitData.is_big_impact(hit, was_stunned)
	velocity = hit.knockback
	_hurt_for = hurt_time
	_wall_stun_armed = hit.wall_stun
	_flash = 1.0
	if hit.stun_time > 0.0:
		stun(hit.stun_time)
	Fx.damage_number(global_position, amount, Color(1, 0.9, 0.3) if was_stunned else Color.WHITE)
	Fx.burst(global_position + Vector2(0, -6), hit_particle_color, 10 if big else 6)
	if big:
		Fx.hitstop(Fx.hitstop_big)
		Fx.shake(0.6)
		Fx.sfx(&"hit_heavy")
	else:
		Fx.hitstop(Fx.hitstop_normal)
		Fx.sfx(&"hit")
		if hit.charged:
			Fx.shake(0.25)
	_on_hurt()
	health.damage(amount)


func _die() -> void:
	_dead = true
	contact_hitbox.active = false
	hurtbox.set_deferred(&"monitorable", false)
	Fx.sfx(&"enemy_die")
	Fx.burst(global_position + Vector2(0, -6), hit_particle_color, 16, 110.0)
	died.emit(self)
	queue_free()


func _update_visuals(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 8.0)
	(sprite.material as ShaderMaterial).set_shader_parameter(&"flash_amount", _flash)
	if is_stunned():
		sprite.rotation = sin(_clock * 25.0) * 0.25
		sprite.self_modulate = Color(0.75, 0.8, 1.0)
	else:
		sprite.rotation = 0.0
		sprite.self_modulate = Color.WHITE
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
