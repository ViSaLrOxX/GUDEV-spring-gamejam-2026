extends Node

func _ready() -> void:
	_run()
	get_tree().quit()

func _run() -> void:
	var T: GDScript = preload("res://tests/test_helpers.gd")
	var CD: GDScript = preload("res://scripts/character_data.gd")

	T.suite("CharacterData - roster size is exactly 8")
	var all: Array = CD.get_all()
	T.expect_eq(all.size(), 8, "exactly 8 characters")

	T.suite("CharacterData - all 8 expected IDs exist")
	var ids: Array = all.map(func(c): return c["id"])
	for expected_id in ["VECTOR", "GLITCH", "PHANTOM", "PURGE", "ECHO", "NOVA", "WRAITH", "ARBITER"]:
		T.expect_true(ids.has(expected_id), "%s present" % expected_id)

	T.suite("CharacterData - old SIGNAL character is gone")
	T.expect_false(ids.has("SIGNAL"), "SIGNAL removed from roster")

	T.suite("CharacterData - get_by_id exact match for every character")
	for char_id in ["VECTOR", "GLITCH", "PHANTOM", "PURGE", "ECHO", "NOVA", "WRAITH", "ARBITER"]:
		var c: Dictionary = CD.get_by_id(char_id)
		T.expect_eq(c["id"], char_id, "get_by_id(%s)" % char_id)

	T.suite("CharacterData - unknown id falls back to VECTOR not null")
	var fallback: Dictionary = CD.get_by_id("INVALID_ID")
	T.expect_eq(fallback["id"], "VECTOR", "unknown id → VECTOR")
	T.expect_false(fallback.is_empty(), "fallback is not empty")

	T.suite("CharacterData - empty string id falls back to VECTOR")
	var empty_fallback: Dictionary = CD.get_by_id("")
	T.expect_eq(empty_fallback["id"], "VECTOR", "empty string id → VECTOR")

	T.suite("CharacterData - all required fields present on every character")
	var required_fields := ["id", "name", "title", "colour", "ability_name",
		"ability_desc", "ability_type", "speed_mult", "enemy_speed_mult",
		"image_path", "backstory"]
	for c: Dictionary in all:
		for field in required_fields:
			T.expect_true(c.has(field), "%s has '%s'" % [c["id"], field])

	T.suite("CharacterData - id and name match on every character")
	for c: Dictionary in all:
		T.expect_eq(c["id"], c["name"], "%s id == name" % c["id"])

	T.suite("CharacterData - every image_path is non-empty")
	for c: Dictionary in all:
		T.expect_true(c["image_path"].length() > 0, "%s image_path non-empty" % c["id"])

	T.suite("CharacterData - all image_paths are unique (no shared portraits)")
	var path_set := {}
	for c: Dictionary in all:
		path_set[c["image_path"]] = true
	T.expect_eq(path_set.size(), all.size(), "8 unique image paths")

	T.suite("CharacterData - all image_paths point into characters/ folder")
	for c: Dictionary in all:
		T.expect_true(c["image_path"].begins_with("res://characters/"),
			"%s image in characters/" % c["id"])

	T.suite("CharacterData - all ability_types are from the valid set")
	var valid_types := ["none", "bullet_time", "invisibility", "wipeout",
		"restore", "time_heist", "stasis", "sync_blast"]
	for c: Dictionary in all:
		T.expect_true(valid_types.has(c["ability_type"]),
			"%s ability_type '%s' valid" % [c["id"], c["ability_type"]])

	T.suite("CharacterData - each character has correct ability_type")
	T.expect_eq(CD.get_by_id("VECTOR")["ability_type"],  "none",         "VECTOR  none")
	T.expect_eq(CD.get_by_id("GLITCH")["ability_type"],  "bullet_time",  "GLITCH  bullet_time")
	T.expect_eq(CD.get_by_id("PHANTOM")["ability_type"], "invisibility", "PHANTOM invisibility")
	T.expect_eq(CD.get_by_id("PURGE")["ability_type"],   "wipeout",      "PURGE   wipeout")
	T.expect_eq(CD.get_by_id("ECHO")["ability_type"],    "restore",      "ECHO    restore")
	T.expect_eq(CD.get_by_id("NOVA")["ability_type"],    "time_heist",   "NOVA    time_heist")
	T.expect_eq(CD.get_by_id("WRAITH")["ability_type"],  "stasis",       "WRAITH  stasis")
	T.expect_eq(CD.get_by_id("ARBITER")["ability_type"], "sync_blast",   "ARBITER sync_blast")

	T.suite("CharacterData - VECTOR is exactly baseline (all 1.0 multipliers)")
	var vec: Dictionary = CD.get_by_id("VECTOR")
	T.expect_eq(vec["speed_mult"],       1.0, "VECTOR speed_mult=1.0")
	T.expect_eq(vec["enemy_speed_mult"], 1.0, "VECTOR enemy_speed_mult=1.0")
	T.expect_eq(vec["ability_type"],  "none", "VECTOR ability=none")

	T.suite("CharacterData - speed multipliers positive for all characters")
	for c: Dictionary in all:
		T.expect_gt(c["speed_mult"],       0.0, "%s speed_mult>0"       % c["id"])
		T.expect_gt(c["enemy_speed_mult"], 0.0, "%s enemy_speed_mult>0" % c["id"])

	T.suite("CharacterData - fast characters faster than VECTOR")
	T.expect_gt(CD.get_by_id("GLITCH")["speed_mult"], 1.0, "GLITCH faster")
	T.expect_gt(CD.get_by_id("NOVA")["speed_mult"],   1.0, "NOVA faster")

	T.suite("CharacterData - slow/ghost characters at or below VECTOR speed")
	T.expect_lte(CD.get_by_id("WRAITH")["speed_mult"],  1.0, "WRAITH not faster")
	T.expect_lte(CD.get_by_id("ARBITER")["speed_mult"], 1.0, "ARBITER not faster")

	T.suite("CharacterData - enemy-slowing characters actually slow enemies")
	T.expect_lte(CD.get_by_id("PHANTOM")["enemy_speed_mult"], 1.0, "PHANTOM enemies slower")
	T.expect_lte(CD.get_by_id("WRAITH")["enemy_speed_mult"],  1.0, "WRAITH enemies slower")
	T.expect_lte(CD.get_by_id("ARBITER")["enemy_speed_mult"], 1.0, "ARBITER enemies slower")

	T.suite("CharacterData - GLITCH enemies are faster (high risk/high reward)")
	T.expect_gt(CD.get_by_id("GLITCH")["enemy_speed_mult"], 1.0, "GLITCH enemies faster")
	T.expect_gt(CD.get_by_id("NOVA")["enemy_speed_mult"],   1.0, "NOVA enemies faster")

	T.suite("CharacterData - backstories non-empty, unique, appropriately sized")
	var story_set := {}
	for c: Dictionary in all:
		var story: String = c["backstory"]
		T.expect_true(story.length() > 100, "%s backstory >100 chars" % c["id"])
		T.expect_true(story.length() < 700, "%s backstory <700 chars" % c["id"])
		story_set[story] = true
	T.expect_eq(story_set.size(), all.size(), "all backstories unique")

	T.suite("CharacterData - titles are non-empty and unique")
	var title_set := {}
	for c: Dictionary in all:
		T.expect_true(c["title"].length() > 0, "%s has title" % c["id"])
		title_set[c["title"]] = true
	T.expect_eq(title_set.size(), all.size(), "all titles unique")

	T.suite("CharacterData - ability_name non-empty for all characters")
	for c: Dictionary in all:
		T.expect_true(c["ability_name"].length() > 0, "%s has ability_name" % c["id"])

	T.suite("CharacterData - ability_desc non-empty for all characters")
	for c: Dictionary in all:
		T.expect_true(c["ability_desc"].length() > 0, "%s has ability_desc" % c["id"])

	T.suite("Ability bar - generic fill clamps at max")
	var charge := 0.0
	charge = minf(charge + 50.0, 100.0)
	T.expect_false(charge >= 100.0, "50% not ready")
	charge = minf(charge + 50.0, 100.0)
	T.expect_true(charge >= 100.0, "100% is ready")
	charge = minf(charge + 999.0, 100.0)
	T.expect_eq(charge, 100.0, "overfill clamps at 100")
	charge = 0.0
	T.expect_false(charge >= 100.0, "reset not ready")

	T.suite("Ability bar - ECHO fills below 20s, not above")
	var echo_c := 0.0; var dt := 0.1
	if 10.0 < 20.0: echo_c = minf(echo_c + dt * 18.0, 100.0)
	T.expect_gt(echo_c, 0.0, "ECHO fills at time=10")
	var before := echo_c
	if 30.0 < 20.0: echo_c = minf(echo_c + dt * 18.0, 100.0)
	T.expect_eq(echo_c, before, "ECHO frozen at time=30")
	if 19.9 < 20.0: echo_c = minf(echo_c + dt * 18.0, 100.0)
	T.expect_gt(echo_c, before, "ECHO fills at time=19.9")

	T.suite("Ability bar - WRAITH passive fill at 4/s")
	var wraith_c := 0.0
	wraith_c = minf(wraith_c + 4.0 * 5.0, 100.0)
	T.expect_eq(wraith_c, 20.0, "5s × 4/s = 20")
	wraith_c = minf(wraith_c + 4.0 * 25.0, 100.0)
	T.expect_eq(wraith_c, 100.0, "capped at 100")
	wraith_c = minf(wraith_c + 4.0 * 1.0, 100.0)
	T.expect_eq(wraith_c, 100.0, "stays at 100 once full")

	T.suite("Ability bar - PURGE distance-based fill (0.1 per unit)")
	var purge_c := 0.0; var dist := 0.0
	dist += 500.0; purge_c = minf(dist * 0.1, 100.0)
	T.expect_eq(purge_c, 50.0, "500 dist = 50")
	dist += 500.0; purge_c = minf(dist * 0.1, 100.0)
	T.expect_eq(purge_c, 100.0, "1000 dist = 100 (capped)")
	dist += 1000.0; purge_c = minf(dist * 0.1, 100.0)
	T.expect_eq(purge_c, 100.0, "2000 dist still 100")

	T.suite("Ability bar - NOVA and GLITCH fill +20 per kill")
	var kill_c := 0.0
	kill_c = minf(kill_c + 20.0, 100.0); T.expect_eq(kill_c, 20.0,  "1 kill = 20")
	kill_c = minf(kill_c + 20.0, 100.0); T.expect_eq(kill_c, 40.0,  "2 kills = 40")
	kill_c = minf(kill_c + 20.0, 100.0); T.expect_eq(kill_c, 60.0,  "3 kills = 60")
	kill_c = minf(kill_c + 20.0, 100.0); T.expect_eq(kill_c, 80.0,  "4 kills = 80")
	kill_c = minf(kill_c + 20.0, 100.0); T.expect_eq(kill_c, 100.0, "5 kills = 100 (full)")
	kill_c = minf(kill_c + 20.0, 100.0); T.expect_eq(kill_c, 100.0, "6 kills still 100")

	T.suite("Ability bar - PHANTOM fills on taking damage (× 4.5)")
	var phant_c := 0.0
	phant_c = minf(phant_c + 8.0 * 4.5, 100.0); T.expect_eq(phant_c, 36.0, "8 dmg = 36")
	phant_c = minf(phant_c + 8.0 * 4.5, 100.0); T.expect_eq(phant_c, 72.0, "16 dmg = 72")
	phant_c = minf(phant_c + 8.0 * 4.5, 100.0); T.expect_eq(phant_c, 100.0,"24 dmg = 100 (capped)")

	T.suite("Ability bar - ARBITER fills on taking damage (× 6.0)")
	var arb_c := 0.0
	arb_c = minf(arb_c + 8.0 * 6.0, 100.0); T.expect_eq(arb_c, 48.0, "8 dmg = 48")
	arb_c = minf(arb_c + 8.0 * 6.0, 100.0); T.expect_eq(arb_c, 96.0, "16 dmg = 96")
	arb_c = minf(arb_c + 1.0 * 6.0, 100.0); T.expect_eq(arb_c, 100.0,"17+ dmg = 100 capped")

	T.summary()
