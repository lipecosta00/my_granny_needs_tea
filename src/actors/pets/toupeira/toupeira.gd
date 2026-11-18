class_name Toupeira
extends Pet
## GDD: Mordida — darts at the nearest enemy and back every 1.4 s; RB combat
## = Tremor (a line in front of the hero that stuns for 1.2 s); RB
## exploration = tunnel under fences.

@export_group("Toupeira")
@export var bite_damage := 1
@export var bite_speed := 240.0
@export var bite_max_time := 0.4
@export var tremor_length := 80.0
@export var tremor_half_width := 14.0
@export var tremor_stun_time := 1.2

var _bite_target: Enemy
var _bite_time := 0.0


func _auto_attack(target: Node2D) -> void:
	_bite_target = target as Enemy
	_bite_time = 0.0


func _custom_motion(delta: float) -> bool:
	if not is_instance_valid(_bite_target) or is_out:
		_bite_target = null
		return false
	_bite_time += delta
	var to_target := _bite_target.global_position - global_position
	if to_target.length() <= 8.0:
		var hit := HitData.make(bite_damage, to_target.normalized() * 80.0, HitData.Team.HERO, self)
		hit.from_pet = true
		_bite_target.hurtbox.receive(hit)
		Fx.sfx(&"hit", 0.15)
		_bite_target = null
		return false
	if _bite_time >= bite_max_time:
		_bite_target = null
		return false
	velocity = to_target.normalized() * bite_speed
	global_position += velocity * delta
	return true


func _combat_ability() -> void:
	for enemy in _enemies():
		if in_line(hero.global_position, hero.facing, enemy.global_position, tremor_length, tremor_half_width):
			enemy.stun(tremor_stun_time)
	for i in 6:
		var at := hero.global_position + hero.facing * (12.0 + i * tremor_length / 6.0)
		Fx.burst(at, Color(0.55, 0.45, 0.3), 5, 40.0)
	Fx.sfx(&"hit_heavy")
	Fx.shake(0.35)


static func in_line(origin: Vector2, facing: Vector2, point: Vector2, length: float, half_width: float) -> bool:
	var offset := point - origin
	var along := offset.dot(facing.normalized())
	var across := absf(offset.dot(facing.normalized().orthogonal()))
	return along > 0.0 and along <= length and across <= half_width
