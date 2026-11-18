class_name Hurtbox
extends Area2D
## Receives hits. The owner decides what a hit means (damage, knockback...).

signal hit_received(hit: HitData)

@export var team := HitData.Team.HERO
## I-frames (roll, post-damage) flip this instead of disabling the shape,
## so overlap state stays consistent.
var invulnerable := false


func _ready() -> void:
	monitoring = false
	monitorable = true


## Returns true when the hit was accepted.
func receive(hit: HitData) -> bool:
	if invulnerable or hit.team == team:
		return false
	hit_received.emit(hit)
	return true
