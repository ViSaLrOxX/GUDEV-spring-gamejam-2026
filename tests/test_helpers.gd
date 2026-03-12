extends Node

static var _pass_count : int = 0
static var _fail_count : int = 0
static var _current_suite : String = ""

static func suite(name: String) -> void:
	_current_suite = name
	print("\n=== %s ===" % name)

static func expect_eq(actual, expected, label: String = "") -> void:
	if actual == expected:
		_pass_count += 1
		print("  PASS  %s" % label)
	else:
		_fail_count += 1
		print("  FAIL  %s  expected=%s  got=%s" % [label, str(expected), str(actual)])

static func expect_true(value: bool, label: String = "") -> void:
	expect_eq(value, true, label)

static func expect_false(value: bool, label: String = "") -> void:
	expect_eq(value, false, label)

static func expect_gt(actual, threshold, label: String = "") -> void:
	if actual > threshold:
		_pass_count += 1
		print("  PASS  %s  (%s > %s)" % [label, str(actual), str(threshold)])
	else:
		_fail_count += 1
		print("  FAIL  %s  expected %s > %s" % [label, str(actual), str(threshold)])

static func expect_lte(actual, threshold, label: String = "") -> void:
	if actual <= threshold:
		_pass_count += 1
		print("  PASS  %s  (%s <= %s)" % [label, str(actual), str(threshold)])
	else:
		_fail_count += 1
		print("  FAIL  %s  expected %s <= %s" % [label, str(actual), str(threshold)])

static func summary() -> void:
	print("\n--- Results: %d passed, %d failed ---" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
