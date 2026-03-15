extends Node

func _ready() -> void:
	_run()
	get_tree().quit()

func _run() -> void:
	var H := preload("res://scripts/highscore.gd")
	var T := preload("res://tests/test_helpers.gd")

	T.suite("Highscore - initial state is all zeroes")
	var hs := H.new()
	T.expect_eq(hs.best_round, 0,   "best_round=0")
	T.expect_eq(hs.best_kills, 0,   "best_kills=0")
	T.expect_eq(hs.best_time,  0.0, "best_time=0.0")

	T.suite("Highscore - first ever submit is always a new best")
	var is_new := hs.submit(5, 12, 42.5)
	T.expect_true(is_new,           "first submit = new best")
	T.expect_eq(hs.best_round, 5,   "best_round → 5")
	T.expect_eq(hs.best_kills, 12,  "best_kills → 12")
	T.expect_eq(hs.best_time, 42.5, "best_time  → 42.5")

	T.suite("Highscore - lower scores on all fields do not overwrite")
	var is_new2 := hs.submit(3, 5, 10.0)
	T.expect_false(is_new2,         "lower round not new best")
	T.expect_eq(hs.best_round, 5,   "best_round stays 5")
	T.expect_eq(hs.best_kills, 12,  "best_kills stays 12")
	T.expect_eq(hs.best_time, 42.5, "best_time stays 42.5")

	T.suite("Highscore - equal round is NOT new best")
	var hs2 := H.new(); hs2.submit(5, 10, 30.0)
	var is_equal := hs2.submit(5, 20, 60.0)
	T.expect_false(is_equal, "equal round not new best")
	T.expect_eq(hs2.best_kills, 20,  "kills still improved independently")
	T.expect_eq(hs2.best_time,  60.0,"time still improved independently")

	T.suite("Highscore - higher round is new best")
	var is_new3 := hs.submit(10, 3, 5.0)
	T.expect_true(is_new3,          "round 10 > 5 = new best")
	T.expect_eq(hs.best_round, 10,  "best_round → 10")
	T.expect_eq(hs.best_kills, 12,  "best_kills unchanged (3 < 12)")
	T.expect_eq(hs.best_time, 42.5, "best_time unchanged (5.0 < 42.5)")

	T.suite("Highscore - kills improve independently of round")
	var is_new4 := hs.submit(1, 999, 1.0)
	T.expect_false(is_new4,         "round 1 not new best")
	T.expect_eq(hs.best_kills, 999, "kills → 999")
	T.expect_eq(hs.best_round, 10,  "round unchanged")

	T.suite("Highscore - time improves independently of round")
	var is_new5 := hs.submit(1, 1, 9999.9)
	T.expect_false(is_new5,            "round 1 not new best")
	T.expect_eq(hs.best_time, 9999.9,  "time → 9999.9")
	T.expect_eq(hs.best_round, 10,     "round unchanged")

	T.suite("Highscore - zero values do not overwrite existing bests")
	var hs3 := H.new(); hs3.submit(8, 20, 55.0)
	hs3.submit(0, 0, 0.0)
	T.expect_eq(hs3.best_round, 8,    "best_round protected from 0")
	T.expect_eq(hs3.best_kills, 20,   "best_kills protected from 0")
	T.expect_eq(hs3.best_time, 55.0,  "best_time protected from 0")

	T.suite("Highscore - submit returns false when only time improves")
	var hs4 := H.new(); hs4.submit(3, 10, 20.0)
	var only_time := hs4.submit(2, 5, 99.0)
	T.expect_false(only_time, "false when only time improved")
	T.expect_eq(hs4.best_time, 99.0, "time still updated")

	T.suite("Highscore - submit returns false when only kills improve")
	var hs5 := H.new(); hs5.submit(3, 10, 20.0)
	var only_kills := hs5.submit(1, 100, 5.0)
	T.expect_false(only_kills, "false when only kills improved")
	T.expect_eq(hs5.best_kills, 100, "kills still updated")

	T.suite("Highscore - large values accepted")
	var hs6 := H.new()
	var is_big := hs6.submit(9999, 99999, 999999.9)
	T.expect_true(is_big,                "large values accepted")
	T.expect_eq(hs6.best_round, 9999,    "large round stored")
	T.expect_eq(hs6.best_kills, 99999,   "large kills stored")
	T.expect_eq(hs6.best_time, 999999.9, "large time stored")

	T.suite("Highscore - reset clears everything to zero")
	hs.reset()
	T.expect_eq(hs.best_round, 0,   "reset → round=0")
	T.expect_eq(hs.best_kills, 0,   "reset → kills=0")
	T.expect_eq(hs.best_time,  0.0, "reset → time=0.0")

	T.suite("Highscore - submit works normally after reset")
	var post_reset := hs.submit(2, 8, 15.5)
	T.expect_true(post_reset,       "post-reset submit = new best")
	T.expect_eq(hs.best_round, 2,   "round → 2")
	T.expect_eq(hs.best_kills, 8,   "kills → 8")
	T.expect_eq(hs.best_time, 15.5, "time  → 15.5")

	T.suite("Highscore - multiple resets are safe")
	hs.reset(); hs.reset(); hs.reset()
	T.expect_eq(hs.best_round, 0,   "triple reset: round=0")
	T.expect_eq(hs.best_kills, 0,   "triple reset: kills=0")
	T.expect_eq(hs.best_time,  0.0, "triple reset: time=0.0")

	T.summary()
