extends HeroInput
## Scripted controller for hero/pet integration tests.

var move := Vector2.ZERO
var held := {}

func move_vector() -> Vector2:
	return move

func feed(_event: InputEvent) -> void:
	pass  # ignore the real keyboard/pad while scripted

func tap(action: StringName) -> void:
	_pending.append(action)

func hold(action: StringName) -> void:
	_pending.append(action)
	held[action] = true

func release(action: StringName) -> void:
	held.erase(action)

func is_held(action: StringName) -> bool:
	return held.has(action)
