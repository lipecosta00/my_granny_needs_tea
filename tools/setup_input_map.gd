## Writes the input map from the GDD control table into project.godot.
##
## Single source of truth for bindings: edit BINDINGS, then run
##   godot --headless --path . -s tools/setup_input_map.gd
## Godot's JoyButton enum follows the SDL/Xbox layout (A bottom, B right, X left,
## Y top), which maps positionally to PlayStation (Cross, Circle, Square, Triangle).
extends SceneTree

const MOVE_DEADZONE := 0.2
const BUTTON_DEADZONE := 0.5

## action -> { keys, joy_buttons, joy_axes: [[axis, direction]], deadzone }
const BINDINGS := {
	# Movement: left stick + WASD/arrows. D-pad is reserved for souls/potion
	# (see GDD "Controles"), so it does not move the hero.
	"move_left": {"keys": [KEY_A, KEY_LEFT], "joy_axes": [[JOY_AXIS_LEFT_X, -1.0]], "deadzone": MOVE_DEADZONE},
	"move_right": {"keys": [KEY_D, KEY_RIGHT], "joy_axes": [[JOY_AXIS_LEFT_X, 1.0]], "deadzone": MOVE_DEADZONE},
	"move_up": {"keys": [KEY_W, KEY_UP], "joy_axes": [[JOY_AXIS_LEFT_Y, -1.0]], "deadzone": MOVE_DEADZONE},
	"move_down": {"keys": [KEY_S, KEY_DOWN], "joy_axes": [[JOY_AXIS_LEFT_Y, 1.0]], "deadzone": MOVE_DEADZONE},
	"attack_primary": {"keys": [KEY_J], "joy_buttons": [JOY_BUTTON_X]},
	"attack_secondary": {"keys": [KEY_K], "joy_buttons": [JOY_BUTTON_Y]},
	"roll": {"keys": [KEY_SPACE], "joy_buttons": [JOY_BUTTON_B]},
	"interact": {"keys": [KEY_E], "joy_buttons": [JOY_BUTTON_A]},
	"weapon_wheel": {"keys": [KEY_Q], "joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"soul_ability": {"keys": [KEY_R], "joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	"soul_prev": {"keys": [KEY_1], "joy_buttons": [JOY_BUTTON_DPAD_LEFT]},
	"soul_next": {"keys": [KEY_2], "joy_buttons": [JOY_BUTTON_DPAD_RIGHT]},
	"potion": {"keys": [KEY_F], "joy_buttons": [JOY_BUTTON_DPAD_UP]},
	"pause": {"keys": [KEY_ESCAPE], "joy_buttons": [JOY_BUTTON_START]},
}


func _init() -> void:
	for action: String in BINDINGS:
		var spec: Dictionary = BINDINGS[action]
		var events: Array[InputEvent] = []
		for keycode: int in spec.get("keys", []):
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			key.device = -1
			events.append(key)
		for button: int in spec.get("joy_buttons", []):
			var joy_button := InputEventJoypadButton.new()
			joy_button.button_index = button
			joy_button.device = -1
			events.append(joy_button)
		for axis_spec: Array in spec.get("joy_axes", []):
			var motion := InputEventJoypadMotion.new()
			motion.axis = axis_spec[0]
			motion.axis_value = axis_spec[1]
			motion.device = -1
			events.append(motion)
		ProjectSettings.set_setting("input/" + action, {
			"deadzone": spec.get("deadzone", BUTTON_DEADZONE),
			"events": events,
		})
	var err := ProjectSettings.save()
	print("input map: %d actions written (%s)" % [BINDINGS.size(), error_string(err)])
	quit(0 if err == OK else 1)
