class_name InputBuffer
extends RefCounted
## Remembers presses for a short window (GDD: 0.15 s for attack and roll), so a
## button hit at the tail of an animation fires as soon as the hero is free.
## Time is supplied by the caller (gameplay clock), so hitstop freezes it too.

var window := 0.15
var _pressed_at := {}  # action -> time


func _init(buffer_window := 0.15) -> void:
	window = buffer_window


func press(action: StringName, now: float) -> void:
	_pressed_at[action] = now


## True (and clears it) if [param action] was pressed within the window.
func consume(action: StringName, now: float) -> bool:
	if not _pressed_at.has(action):
		return false
	var fresh: bool = now - _pressed_at[action] <= window
	_pressed_at.erase(action)
	return fresh


func peek(action: StringName, now: float) -> bool:
	return _pressed_at.has(action) and now - _pressed_at[action] <= window


func clear() -> void:
	_pressed_at.clear()
