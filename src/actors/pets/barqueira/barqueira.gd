class_name Barqueira
extends Pet
## GDD: wave that pushes the enemy every 1.5 s; RB combat = Remo (pulls the
## enemies in a cone in front of the hero); RB exploration = mist bridge.

@export_group("Barqueira")
@export var wave_damage := 1
@export var wave_reach := 30.0
@export var wave_push := 220.0
## Remo cone in front of the hero.
@export var remo_range := 80.0
@export var remo_half_angle := 45.0
## Brief stun so pulled crabs can't hide behind their shell.
@export var remo_stun_time := 0.6
## Pulled enemies stop about this far in front of the hero.
@export var remo_stop_distance := 18.0


func _auto_attack(target: Node2D) -> void:
	if target.global_position.distance_to(global_position) > wave_reach:
		_attack_timer = 0.2  # get closer first
		return
	var away := (target.global_position - global_position).normalized()
	var hit := HitData.make(wave_damage, away * wave_push, HitData.Team.HERO, self)
	hit.from_pet = true
	hit.wall_stun = true  # GDD: pushed into a wall = stunned 1 s
	(target as Enemy).hurtbox.receive(hit)
	Fx.ring(target.global_position + Vector2(0, -6), 14.0, color, 0.25)
	Fx.sfx(&"roll", 0.1)


func _combat_ability() -> void:
	var friction_rate := 900.0
	for enemy in _enemies():
		if in_cone(hero.global_position, hero.facing, enemy.global_position, remo_range, remo_half_angle):
			var to_hero := hero.global_position - enemy.global_position
			var travel := maxf(0.0, to_hero.length() - remo_stop_distance)
			# v² = 2·a·d: lands right in front of the hero under knockback friction.
			var speed := sqrt(2.0 * friction_rate * travel)
			enemy.displace(to_hero.normalized() * speed / maxf(0.1, 1.0 - enemy.knockback_resistance), remo_stun_time)
	var tip := hero.global_position + hero.facing * remo_range * 0.6 + Vector2(0, -6)
	Fx.ring(tip, remo_range * 0.5, color, 0.35)
	Fx.sfx(&"flash")
	Fx.shake(0.15)


static func in_cone(origin: Vector2, facing: Vector2, point: Vector2, reach: float, half_angle_degrees: float) -> bool:
	var offset := point - origin
	if offset.length() > reach or offset.is_zero_approx():
		return false
	return facing.normalized().dot(offset.normalized()) >= cos(deg_to_rad(half_angle_degrees))
