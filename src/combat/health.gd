class_name Health
extends Node
## Hit points. The hero uses half-hearts as units (6 hearts = 12).

signal changed(current: int, maximum: int)
signal depleted

@export var max_health := 12:
	set(value):
		max_health = maxi(1, value)
		current = mini(current, max_health)

var current := 12


func _ready() -> void:
	current = max_health


func is_dead() -> bool:
	return current <= 0


## Returns the damage actually applied (never below zero health).
func damage(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var applied := mini(amount, current)
	current -= applied
	changed.emit(current, max_health)
	if current == 0:
		depleted.emit()
	return applied


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	current = mini(current + amount, max_health)
	changed.emit(current, max_health)


func reset() -> void:
	current = max_health
	changed.emit(current, max_health)
