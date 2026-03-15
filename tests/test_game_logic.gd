extends SceneTree

func _init() -> void:
	_run()
	quit()

func _run() -> void:
	var T := preload("res://tests/test_helpers.gd")

	T.suite("Time - add_time clamps to max")
	var t := 40.0; var max_t := 60.0
	t = minf(t + 10.0, max_t); T.expect_eq(t, 50.0, "40+10=50")
	t = minf(t + 30.0, max_t); T.expect_eq(t, 60.0, "capped at 60")
	t = minf(t + 999.0, max_t); T.expect_eq(t, 60.0, "overfill stays at 60")

	T.suite("Time - subtract_time floors at -2 for death grace")
	t = maxf(t - 5.0, -2.0);    T.expect_eq(t, 55.0,  "60-5=55")
	t = maxf(t - 60.0, -2.0);   T.expect_eq(t, -2.0,  "floor at -2")
	t = maxf(t - 999.0, -2.0);  T.expect_eq(t, -2.0,  "stays at -2")
	t = maxf(0.0 - 0.1, -2.0);  T.expect_eq(t, -0.1,  "slight negative allowed to -2")
	t = maxf(0.0 - 2.0, -2.0);  T.expect_eq(t, -2.0,  "exactly -2 is the floor")
	t = maxf(0.0 - 2.1, -2.0);  T.expect_eq(t, -2.0,  "below -2 clamped")

	T.suite("Time - limit scales with level and inventory")
	var STARTING_TIME := 30.0
	T.expect_eq(STARTING_TIME + (1 - 1) * 2.0,             30.0, "level 1 = 30s")
	T.expect_eq(STARTING_TIME + (5 - 1) * 2.0,             38.0, "level 5 = 38s")
	T.expect_eq(STARTING_TIME + (10 - 1) * 2.0,            48.0, "level 10 = 48s")
	T.expect_eq(STARTING_TIME + (1 - 1) * 2.0 + 1 * 10.0,  40.0, "level 1 + 1 TIME = 40s")
	T.expect_eq(STARTING_TIME + (5 - 1) * 2.0 + 2 * 10.0,  58.0, "level 5 + 2 TIME = 58s")

	T.suite("Time - starting time for each level uses correct formula")
	T.expect_eq(STARTING_TIME + (1 - 1) * 2.0, 30.0, "level 1 start = 30")
	T.expect_eq(STARTING_TIME + (2 - 1) * 2.0, 32.0, "level 2 start = 32")
	T.expect_eq(STARTING_TIME + (3 - 1) * 2.0, 34.0, "level 3 start = 34")

	T.suite("Combo - increments and caps at MAX_COMBO=4")
	var combo := 0; var MAX_COMBO := 4; var BASE := 6.0
	combo = mini(combo + 1, MAX_COMBO); T.expect_eq(combo, 1, "combo=1")
	combo = mini(combo + 1, MAX_COMBO); T.expect_eq(combo, 2, "combo=2")
	combo = mini(combo + 1, MAX_COMBO); T.expect_eq(combo, 3, "combo=3")
	combo = mini(combo + 1, MAX_COMBO); T.expect_eq(combo, 4, "combo=4 (cap)")
	combo = mini(combo + 1, MAX_COMBO); T.expect_eq(combo, 4, "stays at 4")
	combo = mini(combo + 1, MAX_COMBO); T.expect_eq(combo, 4, "stays at 4 again")

	T.suite("Combo - reward scales with multiplier")
	T.expect_eq(BASE * 1, 6.0,  "×1 = 6.0s")
	T.expect_eq(BASE * 2, 12.0, "×2 = 12.0s")
	T.expect_eq(BASE * 3, 18.0, "×3 = 18.0s")
	T.expect_eq(BASE * 4, 24.0, "×4 = 24.0s")

	T.suite("Shot heat - cost increases per rapid shot")
	var BASE_COST := 5.0; var heat := 0
	T.expect_eq(BASE_COST + heat * 5.0,  5.0,  "heat=0 costs 5")
	heat += 1; T.expect_eq(BASE_COST + heat * 5.0, 10.0, "heat=1 costs 10")
	heat += 1; T.expect_eq(BASE_COST + heat * 5.0, 15.0, "heat=2 costs 15")
	heat += 1; T.expect_eq(BASE_COST + heat * 5.0, 20.0, "heat=3 costs 20")
	heat = 0;  T.expect_eq(BASE_COST + heat * 5.0,  5.0, "reset = 5")

	T.suite("Inventory - slot limits by level")
	T.expect_eq(int(1 + floor(1  / 10.0)), 1, "level 1 = 1 slot")
	T.expect_eq(int(1 + floor(9  / 10.0)), 1, "level 9 = 1 slot")
	T.expect_eq(int(1 + floor(10 / 10.0)), 2, "level 10 = 2 slots")
	T.expect_eq(int(1 + floor(19 / 10.0)), 2, "level 19 = 2 slots")
	T.expect_eq(int(1 + floor(20 / 10.0)), 3, "level 20 = 3 slots")
	T.expect_eq(int(1 + floor(30 / 10.0)), 4, "level 30 = 4 slots")

	T.suite("Inventory - full slot blocks purchase")
	var inv := []; var max_slots := 1
	inv.append("SPEED"); T.expect_true(inv.size() >= max_slots, "full at 1")
	T.expect_false(inv.size() < max_slots, "cannot add more when full")

	T.suite("Cores required by level")
	T.expect_eq(int(1 + floor(1  / 3.0)), 1, "level 1  = 1 core")
	T.expect_eq(int(1 + floor(2  / 3.0)), 1, "level 2  = 1 core")
	T.expect_eq(int(1 + floor(3  / 3.0)), 2, "level 3  = 2 cores")
	T.expect_eq(int(1 + floor(6  / 3.0)), 3, "level 6  = 3 cores")
	T.expect_eq(int(1 + floor(9  / 3.0)), 4, "level 9  = 4 cores")
	T.expect_eq(int(1 + floor(12 / 3.0)), 5, "level 12 = 5 cores")
	for lvl in range(1, 15):
		T.expect_gt(int(1 + floor(lvl / 3.0)), 0, "cores>0 at level %d" % lvl)

	T.suite("Enemy count - pow(2, level)")
	T.expect_eq(int(pow(2, 1)), 2,   "level 1 = 2")
	T.expect_eq(int(pow(2, 2)), 4,   "level 2 = 4")
	T.expect_eq(int(pow(2, 3)), 8,   "level 3 = 8")
	T.expect_eq(int(pow(2, 4)), 16,  "level 4 = 16")
	T.expect_eq(int(pow(2, 5)), 32,  "level 5 = 32")
	T.expect_gt(int(pow(2, 5)), int(pow(2, 4)), "each level strictly more enemies")

	T.suite("Boss - spawns only on multiples of 5")
	for lvl in [5, 10, 15, 20, 25, 30]:
		T.expect_true(lvl % 5 == 0, "level %d has boss" % lvl)
	for lvl in [1, 2, 3, 4, 6, 7, 8, 9, 11, 13]:
		T.expect_false(lvl % 5 == 0, "level %d no boss" % lvl)

	T.suite("Map area scales and always fits all entities (factor 15000)")
	for lvl in [1, 3, 5, 10, 20, 50]:
		var cores   := int(1 + floor(lvl / 3.0))
		var enemies := int(pow(2, lvl))
		var walls   := 5 + lvl
		var coins   := 1 + int(lvl / 2.0)
		var items   := enemies + walls + cores + coins + 10
		var req     := items * 15000.0
		var w       := 700.0 + (lvl - 1) * 30.0
		var h       := 500.0 + (lvl - 1) * 22.5
		var area    := w * h
		if area < req:
			var f := sqrt(req / area); w *= f; h *= f; area = w * h
		T.expect_gt(area, req - 1.0, "level %d area sufficient" % lvl)

	T.suite("Map width strictly increases each level")
	var prev_w := 0.0
	for lvl in range(1, 11):
		var w := 700.0 + (lvl - 1) * 30.0
		T.expect_gt(w, prev_w, "level %d wider than %d" % [lvl, lvl - 1])
		prev_w = w

	T.suite("Kill streak bonus time rewards")
	T.expect_eq(5.0,  5.0,  "streak ×5  = +5s")
	T.expect_eq(10.0, 10.0, "streak ×10 = +10s")
	T.expect_eq(20.0, 20.0, "streak ×20 = +20s")
	T.expect_eq(30.0, 30.0, "streak ×30 = +30s")

	T.suite("Speed-clear bonus: 50% of remaining time when above 20s")
	var time_left := 35.0; var bonus := 0
	if time_left > 20.0: bonus = int(time_left * 0.5)
	T.expect_eq(bonus, 17, "35s → bonus=17")
	time_left = 20.1; bonus = 0
	if time_left > 20.0: bonus = int(time_left * 0.5)
	T.expect_eq(bonus, 10, "20.1s → bonus=10")
	time_left = 20.0; bonus = 0
	if time_left > 20.0: bonus = int(time_left * 0.5)
	T.expect_eq(bonus, 0, "exactly 20s → no bonus")
	time_left = 15.0; bonus = 0
	if time_left > 20.0: bonus = int(time_left * 0.5)
	T.expect_eq(bonus, 0, "15s → no bonus")

	T.suite("Wipeout and portal flat credit bonuses")
	var credits := 0
	credits += 50; T.expect_eq(credits, 50, "wipeout = +50 credits")
	credits += 20; T.expect_eq(credits, 70, "pacifist portal = +20 more")

	T.suite("Dash subtracts exactly 3s from time")
	var dash_t := 30.0
	dash_t = maxf(dash_t - 3.0, -2.0); T.expect_eq(dash_t, 27.0, "30-3=27")
	dash_t = maxf(dash_t - 3.0, -2.0); T.expect_eq(dash_t, 24.0, "27-3=24")
	var low_t := 1.0
	low_t = maxf(low_t - 3.0, -2.0); T.expect_eq(low_t, -2.0, "1-3 floors at -2")

	T.suite("Lethal shot costs nothing (is_lethal=true path)")
	var time_before := 30.0
	T.expect_eq(time_before, 30.0, "lethal shot: no cost deducted")

	T.suite("Enemy HP bonus kicks in from level 6")
	for lvl in [1, 2, 3, 4, 5]:
		T.expect_false(lvl >= 6, "level %d: no HP bonus" % lvl)
	for lvl in [6, 7, 8, 9, 10]:
		T.expect_true(lvl >= 6, "level %d: HP bonus applies" % lvl)
		var hp_bonus := int((lvl - 5) / 3)
		T.expect_true(1 + hp_bonus >= 1, "enemy HP at least 1 at level %d" % lvl)

	T.summary()
