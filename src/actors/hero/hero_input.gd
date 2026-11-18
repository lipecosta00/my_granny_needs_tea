class_name HeroInput
extends RefCounted
## Input port for the hero. The default is fed by real input events; tests
## and cutscenes inject a scripted subclass instead.
##
## Presses come from events, not from polling is_action_just_pressed: a tap
## shorter than one frame (press + release in the same frame) is invisible to
## polling in Godot 4.3, and a dropped attack breaks "gostoso no controle".

const BUFFERED_ACTIONS: Array[StringName] = [&"attack_primary", &"attack_secondary", &"roll"]

var _pending: Array[StringName] = []


func move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_held(action: StringName) -> bool:
	return Input.is_action_pressed(action)


## Called by Hero._unhandled_input for every event.
func feed(event: InputEvent) -> void:
	for action in BUFFERED_ACTIONS:
		if event.is_action_pressed(action, false, true):
			_pending.append(action)


## Presses since the last call, in order.
func take_presses() -> Array[StringName]:
	var presses := _pending
	_pending = []
	return presses
