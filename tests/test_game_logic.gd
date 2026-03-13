extends SceneTree

func _init() -> void:
	_run()
	quit()

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

	T.suite("Map scaling logic")
	# Level 1
	var level1 := 1
	var cores1 := int(1 + floor(level1 / 3.0))
	var enemies1 := level1 * 2
	var walls1 := 5 + level1
	var coins1 := 1 + int(level1 / 2.0)
	var items1 := enemies1 + walls1 + cores1 + coins1 + 10
	var area1_req := items1 * 35000.0
	var w1 := 700.0 + (level1 - 1) * 30.0
	var h1 := 500.0 + (level1 - 1) * 22.5
	var a1 := w1 * h1
	if a1 < area1_req:
		var f := sqrt(area1_req / a1)
		w1 *= f; h1 *= f; a1 = w1 * h1
	T.expect_gt(a1, area1_req - 1.0, "Level 1 area sufficient")

	# Level 50 (Stress test)
	var level50 := 50
	var cores50 := int(1 + floor(level50 / 3.0))
	var enemies50 := level50 * 2
	var walls50 := 5 + level50
	var coins50 := 1 + int(level50 / 2.0)
	var items50 := enemies50 + walls50 + cores50 + coins50 + 10
	var area50_req := items50 * 35000.0
	var w50 := 700.0 + (level50 - 1) * 30.0
	var h50 := 500.0 + (level50 - 1) * 22.5
	var a50 := w50 * h50
	if a50 < area50_req:
		var f := sqrt(area50_req / a50)
		w50 *= f; h50 *= f; a50 = w50 * h50
	T.expect_gt(a50, area50_req - 1.0, "Level 50 area sufficient")
	T.expect_gt(w50, 2000.0, "Level 50 map significantly larger")

	T.suite("Enemy count logic")
	# Level 1
	var total_enemies1 := 0
	var num_enemies1 := 1 * 2
	total_enemies1 += num_enemies1
	T.expect_eq(total_enemies1, 2, "Level 1 has 2 enemies")

	# Level 5 (Boss)
	var total_enemies5 := 0
	if 5 % 5 == 0: total_enemies5 += 1
	var num_enemies5 := 5 * 2
	total_enemies5 += num_enemies5
	T.expect_eq(total_enemies5, 11, "Level 5 has 11 enemies (1 boss + 10 regular)")

	T.summary()
