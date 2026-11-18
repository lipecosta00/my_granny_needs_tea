extends "res://tests/test_case.gd"
## Encodes the GDD control rules so a binding change can't silently break them.

const GAMEPLAY_ACTIONS := [
	"move_left", "move_right", "move_up", "move_down",
	"attack_primary", "attack_secondary", "roll", "interact",
	"weapon_wheel", "pet_ability", "potion", "pause",
]
const MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down"]


func test_all_actions_exist() -> void:
	for action in GAMEPLAY_ACTIONS:
		assert_true(InputMap.has_action(action), "missing action %s" % action)


func test_every_action_has_keyboard_and_gamepad() -> void:
	for action in GAMEPLAY_ACTIONS:
		var has_key := false
		var has_pad := false
		for event in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_pad = has_pad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		assert_true(has_key, "%s has no keyboard binding" % action)
		assert_true(has_pad, "%s has no gamepad binding" % action)


func test_move_deadzone_is_point_two() -> void:
	for action in MOVE_ACTIONS:
		assert_almost(InputMap.action_get_deadzone(action), 0.2, 0.0001, action)


func test_nothing_bound_to_triggers() -> void:
	# GDD: browsers misread triggers (0.5 at rest) — no essential action there.
	for action in GAMEPLAY_ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				assert_false(
					event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT],
					"%s is bound to a trigger" % action)


func test_dpad_never_moves_hero() -> void:
	for action in MOVE_ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton:
				assert_false(
					event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT],
					"%s bound to D-pad" % action)


func test_bindings_apply_to_any_device() -> void:
	for action in GAMEPLAY_ACTIONS:
		for event in InputMap.action_get_events(action):
			assert_eq(event.device, -1, "%s %s" % [action, event])
