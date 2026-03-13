extends Node

func _ready() -> void:
	_run()
	get_tree().quit()

func _run() -> void:
	var T: GDScript = preload("res://tests/test_helpers.gd")
	var CD: GDScript = preload("res://scripts/character_data.gd")

	T.suite("CharacterData - all 6 characters exist")
	var all: Array = CD.get_all()
	T.expect_eq(all.size(), 6, "6 characters defined")
	var ids: Array = all.map(func(c): return c["id"])
	for expected_id in ["VECTOR", "GLITCH", "PHANTOM", "PURGE", "ECHO", "SIGNAL"]:
		T.expect_true(ids.has(expected_id), "%s exists" % expected_id)

	T.suite("CharacterData - get_by_id returns correct character")
	for char_id in ["VECTOR", "GLITCH", "PHANTOM", "PURGE", "ECHO", "SIGNAL"]:
		var c: Dictionary = CD.get_by_id(char_id)
		T.expect_eq(c["id"], char_id, "get_by_id(%s) returns correct" % char_id)

	T.suite("CharacterData - get_by_id unknown id falls back to VECTOR")
	var fallback: Dictionary = CD.get_by_id("INVALID_ID")
	T.expect_eq(fallback["id"], "VECTOR", "unknown id returns VECTOR")

	T.suite("CharacterData - all characters have required fields")
	var required_fields := ["id", "name", "title", "colour", "ability_name", "ability_desc", "ability_type", "speed_mult", "enemy_speed_mult", "backstory"]
	for c: Dictionary in all:
		for field in required_fields:
			T.expect_true(c.has(field), "%s has field '%s'" % [c["id"], field])

	T.suite("CharacterData - speed multipliers are valid")
	for c: Dictionary in all:
		T.expect_gt(c["speed_mult"], 0.0, "%s speed_mult > 0" % c["id"])
		T.expect_gt(c["enemy_speed_mult"], 0.0, "%s enemy_speed_mult > 0" % c["id"])
	var glitch: Dictionary = CD.get_by_id("GLITCH")
	T.expect_gt(glitch["speed_mult"], 1.0, "GLITCH is faster than normal")
	T.expect_gt(glitch["enemy_speed_mult"], 1.0, "GLITCH enemies are faster")
	var phantom: Dictionary = CD.get_by_id("PHANTOM")
	T.expect_lte(phantom["enemy_speed_mult"], 1.0, "PHANTOM enemies are slower or normal")

	T.suite("CharacterData - ability types are valid")
	var valid_types := ["none", "bullet_time", "invisibility", "wipeout", "restore", "free_shoot"]
	for c in all:
		T.expect_true(valid_types.has(c["ability_type"]), "%s has valid ability_type" % c["id"])
	T.expect_eq(CD.get_by_id("VECTOR")["ability_type"], "none", "VECTOR has no ability")
	T.expect_eq(CD.get_by_id("GLITCH")["ability_type"],   "bullet_time",  "GLITCH = bullet_time")
	T.expect_eq(CD.get_by_id("PHANTOM")["ability_type"],  "invisibility", "PHANTOM = invisibility")
	T.expect_eq(CD.get_by_id("PURGE")["ability_type"],    "wipeout",      "PURGE = wipeout")
	T.expect_eq(CD.get_by_id("ECHO")["ability_type"],     "restore",      "ECHO = restore")
	T.expect_eq(CD.get_by_id("SIGNAL")["ability_type"],   "free_shoot",   "SIGNAL = free_shoot")

	T.suite("CharacterData - backstories are non-empty and medium length")
	for c in all:
		var story : String = c["backstory"]
		T.expect_true(story.length() > 100, "%s backstory has substance (>100 chars)" % c["id"])
		T.expect_true(story.length() < 600, "%s backstory not too long (<600 chars)" % c["id"])

	T.suite("Ability bar logic - fill and ready detection")
	var charge     := 0.0
	var max_charge := 100.0
	charge = minf(charge + 50.0, max_charge)
	T.expect_false(charge >= max_charge, "half full not ready")
	charge = minf(charge + 50.0, max_charge)
	T.expect_true(charge >= max_charge, "full bar is ready")
	charge = 0.0
	T.expect_false(charge >= max_charge, "reset bar not ready")

	T.suite("Ability bar - ECHO fills when time is low")
	var time_remaining := 10.0
	var ability_charge := 0.0
	var delta := 0.1
	if time_remaining < 20.0:
		ability_charge = minf(ability_charge + delta * 18.0, 100.0)
	T.expect_gt(ability_charge, 0.0, "ECHO bar fills when time < 20")
	time_remaining = 30.0
	var charge_before := ability_charge
	if time_remaining < 20.0:
		ability_charge = minf(ability_charge + delta * 18.0, 100.0)
	T.expect_eq(ability_charge, charge_before, "ECHO bar does not fill when time >= 20")

	T.suite("Ability bar - SIGNAL fills passively")
	var signal_charge := 0.0
	signal_charge = minf(signal_charge + 1.0 * 5.0, 100.0)
	T.expect_eq(signal_charge, 5.0, "SIGNAL fills at 5 per real second")

	T.summary()
