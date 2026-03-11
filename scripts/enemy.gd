extends CharacterBody2D

@export var enemy_type      : String = "melee"
@export var move_speed      : float  = 80.0
@export var melee_range     : float  = 40.0
@export var melee_cooldown  : float  = 1.2
@export var shoot_range     : float  = 300.0
@export var shoot_cooldown  : float  = 2.0
@export var time_damage     : float  = 8.0
@export var ranged_stalk_speed : float = 50.0

var _player        : Node2D = null
var _game          : Node2D = null
var _melee_timer   : float  = 0.0
var _shoot_timer   : float  = 0.0
var _is_dead       : bool   = false

var _projectile_scene : PackedScene = null
var _blood_scene      : PackedScene = null

func _ready() -> void:
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player")
	_game   = get_tree().get_first_node_in_group("game")
	_projectile_scene = load("res://scenes/enemy_projectile.tscn")
	_blood_scene      = load("res://scenes/blood_particle.tscn")

func _physics_process(delta: float) -> void:
	if _is_dead or not _player:
		return
	var to_player := _player.global_position - global_position
	var dist      := to_player.length()
	var dir       := to_player.normalized()
	look_at(_player.global_position)
	match enemy_type:
		"melee":
			_melee_behaviour(delta, dist, dir)
		"ranged":
			_ranged_behaviour(delta, dist, dir)

func _melee_behaviour(delta: float, dist: float, dir: Vector2) -> void:
	_melee_timer -= delta
	if dist > melee_range:
		velocity = dir * move_speed
	else:
		velocity = Vector2.ZERO
		if _melee_timer <= 0.0:
			_melee_attack()
			_melee_timer = melee_cooldown
	move_and_slide()

func _ranged_behaviour(delta: float, dist: float, dir: Vector2) -> void:
	_shoot_timer -= delta
	var desired_dist := shoot_range * 0.6
	if dist > desired_dist + 20.0:
		velocity = dir * ranged_stalk_speed
	elif dist < desired_dist - 20.0:
		velocity = -dir * ranged_stalk_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if dist <= shoot_range and _shoot_timer <= 0.0:
		_shoot_at_player(dir)
		_shoot_timer = shoot_cooldown

func _melee_attack() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage()

func _shoot_at_player(dir: Vector2) -> void:
	if not _projectile_scene:
		return
	var proj := _projectile_scene.instantiate() as Node2D
	get_parent().add_child(proj)
	proj.global_position = global_position
	if proj.has_method("launch"):
		proj.launch(dir * 250.0)

func hit_by_bullet() -> void:
	if _is_dead:
		return
	die()

func die() -> void:
	_is_dead = true
	if _blood_scene:
		var blood := _blood_scene.instantiate()
		get_parent().add_child(blood)
		blood.global_position = global_position
	if _game:
		_game.enemy_killed()
	queue_free()
