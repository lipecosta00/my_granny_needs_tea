extends RefCounted
## Minimal assertion base for the headless runner (tests/run_tests.gd).
## Kept dependency-free on purpose; swap for GUT/gdUnit4 if the suite outgrows it.

var tree: SceneTree
var failures: PackedStringArray = []
var current_test := ""


func fail(message: String) -> void:
	failures.append("%s: %s" % [current_test, message])


func assert_true(condition: bool, message := "expected true") -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message := "expected false") -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		fail("expected %s, got %s %s" % [expected, actual, message])


func assert_almost(actual: float, expected: float, epsilon := 0.001, message := "") -> void:
	if absf(actual - expected) > epsilon:
		fail("expected %f ± %f, got %f %s" % [expected, epsilon, actual, message])


func assert_vec_almost(actual: Vector2, expected: Vector2, epsilon := 0.001, message := "") -> void:
	if actual.distance_to(expected) > epsilon:
		fail("expected %s, got %s %s" % [expected, actual, message])
