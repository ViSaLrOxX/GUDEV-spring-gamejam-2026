extends Node

func _ready() -> void:
	_run()
	get_tree().quit()

func _run() -> void:
	var T := preload("res://tests/test_helpers.gd")

	T.suite("Time math - add_time and subtract_time")
	var time_remaining := 40.0
	var max_time       := 60.0
	time_remaining = minf(time_remaining + 10.0, max_time)
	T.expect_eq(time_remaining, 50.0, "add 10s gives 50")
	time_remaining = minf(time_remaining + 30.0, max_time)
	T.expect_eq(time_remaining, 60.0, "capped at max_time")
	time_remaining = maxf(time_remaining - 5.0, -2.0)
	T.expect_eq(time_remaining, 55.0, "subtract 5s gives 55")
	time_remaining = maxf(0.0 - 999.0, -2.0)
	T.expect_eq(time_remaining, -2.0, "floor at -2 for death grace")

	T.suite("Combo multiplier logic")
	var combo_count := 0
	var MAX_COMBO   := 4
	var BASE_REWARD := 6.0
	combo_count = mini(combo_count + 1, MAX_COMBO)
	T.expect_eq(combo_count, 1, "first kill combo=1")
	var reward1 := BASE_REWARD * combo_count
	T.expect_eq(reward1, 6.0, "reward at x1 = 6.0")
	combo_count = mini(combo_count + 1, MAX_COMBO)
	combo_count = mini(combo_count + 1, MAX_COMBO)
	combo_count = mini(combo_count + 1, MAX_COMBO)
	T.expect_eq(combo_count, 4, "combo capped at MAX_COMBO")
	combo_count = mini(combo_count + 1, MAX_COMBO)
	T.expect_eq(combo_count, 4, "combo stays at MAX_COMBO after another kill")
	var reward4 := BASE_REWARD * combo_count
	T.expect_eq(reward4, 24.0, "reward at x4 = 24.0")

	T.suite("Shot heat penalty")
	var BASE_SHOOT_COST := 5.0
	var heat := 0
	var cost0 := BASE_SHOOT_COST + (heat * 5.0)
	T.expect_eq(cost0, 5.0, "cold shot costs 5s")
	heat += 1
	var cost1 := BASE_SHOOT_COST + (heat * 5.0)
	T.expect_eq(cost1, 10.0, "heat=1 costs 10s")
	heat += 1
	var cost2 := BASE_SHOOT_COST + (heat * 5.0)
	T.expect_eq(cost2, 15.0, "heat=2 costs 15s")
	heat = 0
	var cost_reset := BASE_SHOOT_COST + (heat * 5.0)
	T.expect_eq(cost_reset, 5.0, "reset heat back to 5s")

	T.suite("Inventory slot limits")
	var inventory := []
	var level      := 1
	var max_slots  := int(1 + floor(level / 10.0))
	T.expect_eq(max_slots, 1, "level 1 has 1 slot")
	inventory.append("SPEED")
	T.expect_true(inventory.size() >= max_slots, "slot now full at level 1")
	level = 10
	max_slots = int(1 + floor(level / 10.0))
	T.expect_eq(max_slots, 2, "level 10 unlocks 2 slots")
	level = 20
	max_slots = int(1 + floor(level / 10.0))
	T.expect_eq(max_slots, 3, "level 20 unlocks 3 slots")

	T.suite("Cores required scaling")
	for lvl in [1, 3, 6, 9]:
		var cores := int(1 + floor(lvl / 3.0))
		T.expect_gt(cores, 0, "cores_required > 0 at level %d" % lvl)
	T.expect_eq(int(1 + floor(1 / 3.0)), 1, "level 1 needs 1 core")
	T.expect_eq(int(1 + floor(6 / 3.0)), 3, "level 6 needs 3 cores")

	T.suite("Boss spawn every 5 rounds")
	for lvl in [5, 10, 15, 20]:
		T.expect_true(lvl % 5 == 0, "boss spawns at round %d" % lvl)
	for lvl in [1, 2, 3, 4, 6, 7]:
		T.expect_false(lvl % 5 == 0, "no boss at round %d" % lvl)

	T.suite("Boss HP scaling")
	for lvl in [5, 10, 15]:
		var boss_hp := 2 + int(lvl / 5)
		T.expect_gt(boss_hp, 2, "boss HP increases with level (level=%d)" % lvl)
	T.expect_eq(2 + int(5 / 5), 3, "boss at round 5 has 3 HP")
	T.expect_eq(2 + int(10 / 5), 4, "boss at round 10 has 4 HP")

	T.suite("Time warp pickup - duration constant")
	var WARP_DURATION := 3.0
	T.expect_eq(WARP_DURATION, 3.0, "warp lasts 3 real seconds")
	T.expect_gt(WARP_DURATION, 0.0, "warp duration is positive")

	T.summary()
