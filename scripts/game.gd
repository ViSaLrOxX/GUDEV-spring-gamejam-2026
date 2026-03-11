extends Node2D

const SLOW_TIME_SCALE  : float = 0.05
const NORMAL_TIME_SCALE: float = 1.0
const TIME_LERP_SPEED  : float = 10.0
const STARTING_TIME    : float = 60.0
const CORES_REQUIRED   : int   = 5
const SHOOT_COST       : float = 10.0
const HIT_COST         : float = 8.0
const BASE_KILL_REWARD : float = 5.0
const COMBO_WINDOW     : float = 3.0
const MAX_COMBO        : int   = 4

var time_remaining    : float = STARTING_TIME
var cores_collected   : int   = 0
var coins_collected   : int   = 0
var total_coins       : int   = 0
var portal_unlocked   : bool  = false
var game_active       : bool  = true
var target_time_scale : float = SLOW_TIME_SCALE
var _last_real_ms     : int   = 0
var combo_count       : int   = 0
var combo_timer       : float = 0.0
var shake_duration    : float = 0.0
var shake_strength    : float = 0.0
var _camera_base_pos  : Vector2

@onready var timer_label : Label    = $UI/TimerLabel
@onready var cores_label : Label    = $UI/CoresLabel
@onready var coins_label : Label    = $UI/CoinsLabel
@onready var combo_label : Label    = $UI/ComboLabel
@onready var portal      : Node2D   = $ExitPortal
@onready var camera      : Camera2D = get_node_or_null("Camera2D")

const _ENEMY_SPAWNS := [
	{"pos": Vector2(200, 200),  "type": "melee"},
	{"pos": Vector2(1050, 180), "type": "melee"},
	{"pos": Vector2(180, 580),  "type": "melee"},
	{"pos": Vector2(500, 150),  "type": "melee"},
	{"pos": Vector2(1060, 560), "type": "ranged"},
	{"pos": Vector2(700, 600),  "type": "ranged"},
]

const _CRYSTAL_SPAWNS := [
	Vector2(150, 150), Vector2(1100, 150), Vector2(150, 600),
	Vector2(1100, 600), Vector2(640, 560),
]

const _COIN_SPAWNS := [
	Vector2(400, 150), Vector2(880, 150), Vector2(300, 450),
	Vector2(950, 450), Vector2(640, 280),
]

const _FREEZE_SPAWNS := [
	Vector2(640, 640), Vector2(200, 360),
]

func _ready() -> void:
	add_to_group("game")
	_last_real_ms = Time.get_ticks_msec()
	if camera:
		_camera_base_pos = camera.offset
	_spawn_level()
	total_coins = get_tree().get_nodes_in_group("coins").size()
	_update_ui()

func _spawn_level() -> void:
	var player_scene  := load("res://scenes/player.tscn")
	var enemy_scene   := load("res://scenes/enemy.tscn")
	var crystal_scene := load("res://scenes/time_crystal.tscn")
	var coin_scene    := load("res://scenes/bonus_item.tscn")
	var freeze_scene  := load("res://scenes/time_freeze_pickup.tscn")

	if player_scene:
		var p := player_scene.instantiate()
		p.position = Vector2(640, 360)
		add_child(p)

	if enemy_scene:
		for data in _ENEMY_SPAWNS:
			var e := enemy_scene.instantiate()
			e.position    = data["pos"]
			e.enemy_type  = data["type"]
			add_child(e)

	if crystal_scene:
		for pos in _CRYSTAL_SPAWNS:
			var c := crystal_scene.instantiate()
			c.position = pos
			add_child(c)

	if coin_scene:
		for pos in _COIN_SPAWNS:
			var co := coin_scene.instantiate()
			co.position = pos
			add_child(co)

	if freeze_scene:
		for pos in _FREEZE_SPAWNS:
			var f := freeze_scene.instantiate()
			f.position = pos
			add_child(f)

func _process(_delta: float) -> void:
	if not game_active:
		return
	var now        : int   = Time.get_ticks_msec()
	var real_delta : float = (now - _last_real_ms) / 1000.0
	_last_real_ms = now
	time_remaining -= real_delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_trigger_game_over()
		return
	Engine.time_scale = lerp(Engine.time_scale, target_time_scale, TIME_LERP_SPEED * real_delta)
	if combo_count > 0:
		combo_timer -= real_delta
		if combo_timer <= 0.0:
			combo_count = 0
			_update_ui()
	if shake_duration > 0.0 and camera:
		shake_duration -= real_delta
		var offset := Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		camera.offset = _camera_base_pos + offset
		if shake_duration <= 0.0:
			camera.offset = _camera_base_pos
	_update_ui()

func set_player_active(active: bool) -> void:
	target_time_scale = NORMAL_TIME_SCALE if active else SLOW_TIME_SCALE

func player_shoot() -> void:
	subtract_time(SHOOT_COST)

func player_hit() -> void:
	subtract_time(HIT_COST)
	trigger_screen_shake(0.25, 12.0)

func enemy_killed() -> void:
	combo_count = mini(combo_count + 1, MAX_COMBO)
	combo_timer = COMBO_WINDOW
	var reward  := BASE_KILL_REWARD * combo_count
	add_time(reward)
	_show_combo_popup(combo_count, reward)

func collect_core() -> void:
	cores_collected += 1
	if cores_collected >= CORES_REQUIRED:
		_unlock_portal()
	_update_ui()

func collect_coin() -> void:
	coins_collected += 1
	_update_ui()

func collect_time_freeze(bonus: float) -> void:
	add_time(bonus)
	_flash_timer_label()

func add_time(amount: float) -> void:
	time_remaining = minf(time_remaining + amount, STARTING_TIME)

func subtract_time(amount: float) -> void:
	time_remaining = maxf(time_remaining - amount, 0.0)
	if time_remaining <= 0.0:
		_trigger_game_over()

func trigger_screen_shake(duration: float, strength: float) -> void:
	shake_duration = duration
	shake_strength = strength

func _unlock_portal() -> void:
	portal_unlocked = true
	if portal and portal.has_method("activate"):
		portal.activate()

func _trigger_game_over() -> void:
	game_active = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func portal_entered() -> void:
	if portal_unlocked:
		game_active = false
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _update_ui() -> void:
	if timer_label:
		timer_label.add_theme_color_override("font_color", Color.RED if time_remaining < 15.0 else Color.WHITE)
		timer_label.text = "TIME  %.1f" % time_remaining
	if cores_label:
		cores_label.text = "CORES  %d / %d" % [cores_collected, CORES_REQUIRED]
	if coins_label and total_coins > 0:
		coins_label.text = "COINS  %d / %d" % [coins_collected, total_coins]
	if combo_label:
		if combo_count > 1:
			combo_label.text     = "COMBO  x%d" % combo_count
			combo_label.modulate = Color.YELLOW
			combo_label.visible  = true
		else:
			combo_label.visible = false

func _show_combo_popup(multiplier: int, reward: float) -> void:
	if not combo_label:
		return
	combo_label.text    = "+%.0fs  x%d" % [reward, multiplier]
	combo_label.visible = true
	var tw := create_tween()
	tw.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.12)

func _flash_timer_label() -> void:
	if not timer_label:
		return
	var tw := create_tween()
	tw.tween_property(timer_label, "modulate", Color.CYAN,  0.15)
	tw.tween_property(timer_label, "modulate", Color.WHITE, 0.25)
