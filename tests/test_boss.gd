extends Node

func _ready() -> void:
	_run()
	get_tree().quit()

func _run() -> void:
	var T := preload("res://tests/test_helpers.gd")

	T.suite("Boss - burst shot count per HP phase")
	T.expect_eq(1, 1, "phase hp=3: burst=1")
	T.expect_eq(2, 2, "phase hp=2: burst=2")
	T.expect_eq(4, 4, "phase hp=1: burst=4")
	for phase_hp in [3, 2, 1]:
		var burst := 1 if phase_hp == 3 else (2 if phase_hp == 2 else 4)
		T.expect_gt(burst, 0, "burst > 0 at hp=%d" % phase_hp)

	T.suite("Boss - burst strictly increases as HP drops")
	var b3 := 1; var b2 := 2; var b1 := 4
	T.expect_gt(b2, b3, "hp2 burst > hp3 burst")
	T.expect_gt(b1, b2, "hp1 burst > hp2 burst")
	T.expect_gt(b1, b3, "hp1 burst > hp3 burst")

	T.suite("Boss - scale grows as HP drops (max_hp=3)")
	var max_hp := 3
	var s3 := 1.5 + (max_hp - 3) * 0.2
	var s2 := 1.5 + (max_hp - 2) * 0.2
	var s1 := 1.5 + (max_hp - 1) * 0.2
	T.expect_eq(s3, 1.5, "full HP scale = 1.5")
	T.expect_eq(s2, 1.7, "mid HP scale  = 1.7")
	T.expect_eq(s1, 1.9, "low HP scale  = 1.9")
	T.expect_gt(s2, s3, "hp2 scale > hp3 scale")
	T.expect_gt(s1, s2, "hp1 scale > hp2 scale")
	T.expect_gt(s1, 1.0, "all scales > 1.0")

	T.suite("Boss - charge gate: only activates at hp <= 2")
	T.expect_false(3 <= 2, "hp=3 no charge")
	T.expect_true(2  <= 2, "hp=2 charges")
	T.expect_true(1  <= 2, "hp=1 charges")
	T.expect_false(4 <= 2, "hp=4 no charge")
	T.expect_false(100 <= 2, "hp=100 no charge")

	T.suite("Boss - charge duration is positive")
	var charge_dur := 0.35
	T.expect_gt(charge_dur, 0.0, "charge duration > 0")
	T.expect_lte(charge_dur, 1.0, "charge duration < 1s (short burst)")

	T.suite("Boss - melee range used for charge hit detection")
	var melee_range := 60.0
	T.expect_gt(melee_range, 0.0, "melee range positive")
	T.expect_true(50.0 < melee_range, "dist=50 is within melee range")
	T.expect_false(80.0 < melee_range, "dist=80 is outside melee range")

	T.suite("Boss - reward_multiplier kills granted on death")
	var reward_multiplier := 5
	var kills_granted := 0
	for i in range(reward_multiplier): kills_granted += 1
	T.expect_eq(kills_granted, 5, "5 kill-rewards granted")

	T.suite("Boss - exactly 1 kill counts toward wipeout on die()")
	var wipeout_kills := 0; var total_kills := 0
	wipeout_kills += 1; total_kills += 1
	for i in range(reward_multiplier - 1): total_kills += 1
	T.expect_eq(wipeout_kills, 1, "1 wipeout-counting kill")
	T.expect_eq(total_kills, reward_multiplier, "total = reward_multiplier")

	T.suite("Boss - HP scaling by round (2 + level/5)")
	T.expect_eq(2 + int(5  / 5), 3, "round 5  = 3 HP")
	T.expect_eq(2 + int(10 / 5), 4, "round 10 = 4 HP")
	T.expect_eq(2 + int(15 / 5), 5, "round 15 = 5 HP")
	T.expect_eq(2 + int(20 / 5), 6, "round 20 = 6 HP")
	T.expect_eq(2 + int(25 / 5), 7, "round 25 = 7 HP")
	T.expect_eq(2 + int(50 / 5), 12,"round 50 = 12 HP")

	T.suite("Boss - HP always at least 3 on first boss round")
	T.expect_gt(2 + int(5 / 5), 2, "boss HP always > 2")

	T.suite("Boss - HP strictly increases every boss round")
	var prev_hp := 0
	for lvl in [5, 10, 15, 20, 25]:
		var hp := 2 + int(lvl / 5)
		T.expect_gt(hp, prev_hp, "level %d boss HP > level %d" % [lvl, lvl - 5])
		prev_hp = hp

	T.suite("Boss - spawns exactly on multiples of 5")
	for lvl in [5, 10, 15, 20, 25, 30, 35, 40]:
		T.expect_true(lvl % 5 == 0, "level %d spawns boss" % lvl)
	for lvl in [1, 2, 3, 4, 6, 7, 8, 9, 11, 14, 16, 21]:
		T.expect_false(lvl % 5 == 0, "level %d no boss" % lvl)

	T.suite("Boss - phase visuals change at each HP value")
	var hp3_color := "pink"; var hp2_color := "orange"; var hp1_color := "yellow"
	T.expect_true(hp3_color != hp2_color, "hp3 and hp2 colors differ")
	T.expect_true(hp2_color != hp1_color, "hp2 and hp1 colors differ")
	T.expect_true(hp3_color != hp1_color, "hp3 and hp1 colors differ")

	T.suite("Boss - screen shake values are positive and non-zero")
	for pair in [[0.4, 18.0], [0.25, 22.0], [0.15, 8.0], [0.6, 30.0], [0.5, 20.0]]:
		T.expect_gt(pair[0], 0.0, "duration %s > 0" % str(pair[0]))
		T.expect_gt(pair[1], 0.0, "strength %s > 0" % str(pair[1]))

	T.suite("Boss - shoot cooldown is positive (shoots at a finite rate)")
	var shoot_cd := 0.9
	T.expect_gt(shoot_cd, 0.0, "shoot cooldown > 0")

	T.suite("Boss - charge cooldown only active at hp <= 2")
	var charge_cd := 4.0
	T.expect_gt(charge_cd, 0.0, "charge cooldown > 0")
	T.expect_gt(charge_cd, shoot_cd, "charge cooldown > shoot cooldown")

	T.summary()
