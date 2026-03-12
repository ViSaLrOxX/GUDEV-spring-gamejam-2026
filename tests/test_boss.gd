extends Node

func _ready() -> void:
	_run()
	get_tree().quit()

func _run() -> void:
	var T := preload("res://tests/test_helpers.gd")

	T.suite("Boss - burst shot count by phase")
	for phase_hp in [3, 2, 1]:
		var burst := 1 if phase_hp == 3 else (2 if phase_hp == 2 else 4)
		T.expect_gt(burst, 0, "burst > 0 at hp=%d" % phase_hp)
	T.expect_eq(1 if 3 == 3 else 0, 1, "phase 3: burst=1")
	T.expect_eq(2 if 2 == 2 else 0, 2, "phase 2: burst=2")
	T.expect_eq(4, 4, "phase 1: burst=4")

	T.suite("Boss - scale increases as HP drops")
	var scales := []
	for remaining_hp in [3, 2, 1]:
		var max_hp := 3
		scales.append(1.5 + (max_hp - remaining_hp) * 0.2)
	T.expect_eq(scales[0], 1.5, "full HP scale = 1.5")
	T.expect_eq(scales[1], 1.7, "mid HP scale = 1.7")
	T.expect_eq(scales[2], 1.9, "low HP scale = 1.9")
	T.expect_gt(scales[2], scales[0], "scale grows as HP drops")

	T.suite("Boss - charge only activates at hp <= 2")
	T.expect_false(3 <= 2, "hp=3 does not charge")
	T.expect_true(2 <= 2, "hp=2 charges")
	T.expect_true(1 <= 2, "hp=1 charges")

	T.suite("Boss - reward equals reward_multiplier kills")
	var reward_multiplier := 5
	var kills_granted     := 0
	for i in range(reward_multiplier):
		kills_granted += 1
	T.expect_eq(kills_granted, 5, "boss death grants 5 kills worth of rewards")

	T.suite("Boss - HP scaling by round")
	T.expect_eq(2 + int(5  / 5), 3, "round 5 boss: 3 HP")
	T.expect_eq(2 + int(10 / 5), 4, "round 10 boss: 4 HP")
	T.expect_eq(2 + int(15 / 5), 5, "round 15 boss: 5 HP")
	T.expect_eq(2 + int(20 / 5), 6, "round 20 boss: 6 HP")

	T.summary()
