extends Node

func _ready() -> void:
	_run()
	get_tree().quit()

func _run() -> void:
	var H := preload("res://scripts/highscore.gd")
	var T := preload("res://tests/test_helpers.gd")

	T.suite("Highscore - initial state")
	var hs := H.new()
	T.expect_eq(hs.best_round, 0, "best_round starts at 0")
	T.expect_eq(hs.best_kills, 0, "best_kills starts at 0")
	T.expect_eq(hs.best_time, 0.0, "best_time starts at 0.0")

	T.suite("Highscore - submit improves scores")
	var is_new := hs.submit(5, 12, 42.5)
	T.expect_true(is_new, "first submit always new best")
	T.expect_eq(hs.best_round, 5, "best_round updated to 5")
	T.expect_eq(hs.best_kills, 12, "best_kills updated to 12")
	T.expect_eq(hs.best_time, 42.5, "best_time updated to 42.5")

	T.suite("Highscore - submit lower scores does not overwrite")
	var is_new2 := hs.submit(3, 5, 10.0)
	T.expect_false(is_new2, "lower round is not new best")
	T.expect_eq(hs.best_round, 5, "best_round stays at 5")
	T.expect_eq(hs.best_kills, 12, "best_kills stays at 12")
	T.expect_eq(hs.best_time, 42.5, "best_time stays at 42.5")

	T.suite("Highscore - submit higher round is new best")
	var is_new3 := hs.submit(10, 3, 5.0)
	T.expect_true(is_new3, "higher round is new best")
	T.expect_eq(hs.best_round, 10, "best_round updated to 10")
	T.expect_eq(hs.best_kills, 12, "best_kills unchanged when lower")
	T.expect_eq(hs.best_time, 42.5, "best_time unchanged when lower")

	T.suite("Highscore - reset clears everything")
	hs.reset()
	T.expect_eq(hs.best_round, 0, "reset clears best_round")
	T.expect_eq(hs.best_kills, 0, "reset clears best_kills")
	T.expect_eq(hs.best_time,  0.0, "reset clears best_time")

	T.summary()
