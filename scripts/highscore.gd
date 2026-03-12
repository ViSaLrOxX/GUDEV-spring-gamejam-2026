extends Node

const _SAVE_PATH := "user://highscore.cfg"

var best_round   : int   = 0
var best_kills   : int   = 0
var best_time    : float = 0.0

func _ready() -> void:
	_load()

func submit(round_reached: int, kills: int, time_survived: float) -> bool:
	var new_best := false
	if round_reached > best_round:
		best_round = round_reached
		new_best   = true
	if kills > best_kills:
		best_kills = kills
	if time_survived > best_time:
		best_time = time_survived
	_save()
	return new_best

func reset() -> void:
	best_round = 0
	best_kills = 0
	best_time  = 0.0
	_save()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "best_round", best_round)
	cfg.set_value("scores", "best_kills", best_kills)
	cfg.set_value("scores", "best_time",  best_time)
	cfg.save(_SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) != OK:
		return
	best_round = cfg.get_value("scores", "best_round", 0)
	best_kills = cfg.get_value("scores", "best_kills", 0)
	best_time  = cfg.get_value("scores", "best_time",  0.0)
