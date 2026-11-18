class_name Pet
extends Node2D
## Spectral companion (GDD "Pets"). Floats through obstacles, so it needs no
## navigation and can't get stuck; teleports back if it falls too far behind.
##
## Subclasses implement _auto_attack() and _combat_ability(). RB is
## contextual: near a closed PetGate this pet can open -> exploration ability,
## otherwise the combat ability (with cooldown).

signal ability_used(kind: StringName)  # &"combat" | &"exploration" | &"fizzle"
signal out_changed(is_out: bool)

@export var pet_id: StringName
@export var display_name := ""
@export var color := Color.WHITE
## Gate ability this pet provides (PetGate.required_ability).
@export var exploration_ability: StringName

@export_group("Movement")
## 1.5 tile behind the hero.
@export var follow_distance := 24.0
@export var max_speed := 120.0
## Higher = snappier follow (arrive steering gain).
@export var steering := 5.0
## Beyond 8 tiles the pet vanishes and reappears beside the hero.
@export var teleport_distance := 128.0

@export_group("Combat")
@export var attack_interval := 1.2
## Targets the nearest enemy within 5 tiles of the pet...
@export var attack_radius := 80.0
## ...but never strays more than 6 tiles from the hero.
@export var leash_radius := 96.0
@export var ability_cooldown := 8.0
@export var out_duration := 5.0
## How close the hero must be to a gate for RB to use the exploration ability.
@export var gate_reach := 40.0

var hero: Hero
var velocity := Vector2.ZERO
var is_out := false
var cooldown_left := 0.0
var _attack_timer := 0.4
var _out_left := 0.0
var _clock := 0.0
var _flash := 0.0

@onready var light_bar: Health = $LightBar
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = %Sprite
@onready var lamp: PointLight2D = $Lamp
@onready var _lamp_energy := lamp.energy
@onready var _visual_base_y := visual.position.y


func _ready() -> void:
	add_to_group(&"pets")
	hurtbox.hit_received.connect(_on_hit_received)
	light_bar.depleted.connect(_go_out)
	sprite.modulate = color
	lamp.color = color


func attach(new_hero: Hero) -> void:
	if hero and hero.pet_ability_pressed.is_connected(use_ability):
		hero.pet_ability_pressed.disconnect(use_ability)
	hero = new_hero
	hero.pet_ability_pressed.connect(use_ability)
	snap_to_hero()


func snap_to_hero() -> void:
	if hero:
		global_position = follow_point(hero.global_position, hero.facing, follow_distance)
		velocity = Vector2.ZERO


## Full light, back in action (respawn, map change).
func restore() -> void:
	light_bar.reset()
	_set_out(false)


func _physics_process(delta: float) -> void:
	if hero == null:
		return
	_clock += delta
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if is_out:
		_out_left -= delta
		if _out_left <= 0.0:
			restore()

	if global_position.distance_to(hero.global_position) > teleport_distance:
		_teleport()

	var target: Enemy = null if is_out else _pick_target()
	var goal := follow_point(hero.global_position, hero.facing, follow_distance)
	if target:
		var toward_hero := (hero.global_position - target.global_position).normalized()
		goal = clamp_to_leash(target.global_position + toward_hero * 20.0, hero.global_position, leash_radius)
	if not _custom_motion(delta):
		var to_goal := goal - global_position
		var desired := to_goal.normalized() * minf(max_speed, to_goal.length() * steering)
		velocity = velocity.lerp(desired, 1.0 - exp(-10.0 * delta))
		global_position += velocity * delta

	if target:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = attack_interval
			_auto_attack(target)
	else:
		_attack_timer = minf(_attack_timer, 0.4)
	_update_visuals(delta)


# --- RB ----------------------------------------------------------------------

func use_ability() -> void:
	if is_out:
		Fx.sfx(&"fizzle")
		ability_used.emit(&"fizzle")
		return
	var gate := find_openable_gate()
	if gate:
		gate.open_with(self)
		_pulse_lamp()
		ability_used.emit(&"exploration")
		return
	if cooldown_left > 0.0:
		Fx.sfx(&"fizzle")
		ability_used.emit(&"fizzle")
		return
	cooldown_left = ability_cooldown
	_combat_ability()
	_pulse_lamp()
	ability_used.emit(&"combat")


func find_openable_gate() -> PetGate:
	if hero == null or exploration_ability == &"":
		return null
	for gate: PetGate in get_tree().get_nodes_in_group(&"pet_gates"):
		if not gate.is_open and gate.required_ability == exploration_ability \
				and gate.distance_to_point(hero.global_position) <= gate_reach:
			return gate
	return null


func cooldown_ratio() -> float:
	return cooldown_left / ability_cooldown if ability_cooldown > 0.0 else 0.0


# --- Hooks ---------------------------------------------------------------------

func _auto_attack(_target: Node2D) -> void:
	pass


func _combat_ability() -> void:
	pass


## Return true when the subclass moved the pet itself this frame (bites).
func _custom_motion(_delta: float) -> bool:
	return false


func _enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if not enemy.is_queued_for_deletion() and not enemy.health.is_dead():
			result.append(enemy)
	return result


# --- Pure helpers (unit-tested) ------------------------------------------------

static func follow_point(hero_pos: Vector2, facing: Vector2, distance: float) -> Vector2:
	return hero_pos - facing * distance


static func clamp_to_leash(point: Vector2, hero_pos: Vector2, leash: float) -> Vector2:
	return hero_pos + (point - hero_pos).limit_length(leash)


## Index of the nearest candidate within [param radius] of [param from], or -1.
static func pick_nearest(from: Vector2, candidates: Array[Vector2], radius: float) -> int:
	var best := -1
	var best_distance := radius
	for i in candidates.size():
		var d := from.distance_to(candidates[i])
		if d <= best_distance:
			best = i
			best_distance = d
	return best


# --- Internals -------------------------------------------------------------------

func _pick_target() -> Enemy:
	var enemies: Array[Enemy] = []
	var positions: Array[Vector2] = []
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.is_queued_for_deletion() or enemy.health.is_dead():
			continue
		enemies.append(enemy)
		positions.append(enemy.global_position)
	var index := pick_nearest(global_position, positions, attack_radius)
	return enemies[index] if index >= 0 else null


func _teleport() -> void:
	Fx.burst(global_position + visual.position, color, 6, 50.0)
	snap_to_hero()
	Fx.burst(global_position + visual.position, color, 6, 50.0)


func _on_hit_received(hit: HitData) -> void:
	if is_out:
		return
	_flash = 1.0
	light_bar.damage(hit.damage)


func _go_out() -> void:
	_out_left = out_duration
	_set_out(true)
	Fx.sfx(&"pet_out")
	Fx.burst(global_position + visual.position, color, 8, 40.0)


func _set_out(value: bool) -> void:
	if is_out == value:
		return
	is_out = value
	hurtbox.invulnerable = value
	out_changed.emit(is_out)


func _pulse_lamp() -> void:
	var tween := create_tween()
	lamp.energy = _lamp_energy * 3.0
	tween.tween_property(lamp, "energy", _lamp_energy, 0.5)


func _update_visuals(delta: float) -> void:
	visual.position.y = _visual_base_y + sin(_clock * 3.0) * 2.0
	if absf(velocity.x) > 4.0:
		sprite.flip_h = velocity.x < 0.0
	_flash = maxf(0.0, _flash - delta * 8.0)
	(sprite.material as ShaderMaterial).set_shader_parameter(&"flash_amount", _flash)
	var alpha := 0.35 if is_out else 0.9
	sprite.modulate = Color(color, alpha)
	if not is_out and lamp.energy <= _lamp_energy:
		lamp.energy = _lamp_energy
	elif is_out:
		lamp.energy = _lamp_energy * 0.25
