extends CharacterBody2D

@export var enemy_type      : String = "melee"
@export var move_speed      : float  = 70.0
@export var melee_range     : float  = 45.0
@export var melee_cooldown  : float  = 1.0
@export var shoot_range     : float  = 350.0
@export var shoot_cooldown  : float  = 1.8
@export var patrol_offset   : Vector2 = Vector2(200, 0)
@export var ranged_stalk_speed : float = 50.0
@export var time_damage     : float  = 8.0
@export var aggro_range     : float  = 400.0

var _player        : Node2D = null
var _game          : Node2D = null
var _melee_timer   : float  = 0.0
var _shoot_timer   : float  = 0.0
var _is_dead       : bool   = false
var _start_pos     : Vector2
var _patrol_target : Vector2
var _going_to_target: bool  = true
var _is_aggroed    : bool   = false

@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
var _projectile_scene : PackedScene = null
var _blood_scene      : PackedScene = null

func _ready() -> void:
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player")
	_game   = get_tree().get_first_node_in_group("game")
	_projectile_scene = load("res://scenes/enemy_projectile.tscn")
	_blood_scene      = load("res://scenes/blood_particle.tscn")
	_start_pos = global_position
	_patrol_target = _start_pos + patrol_offset
	
	# Small delay to ensure NavigationServer is synced
	nav_agent.path_desired_distance = 15.0
	nav_agent.target_desired_distance = 15.0
	
	_setup_visuals()

func _setup_visuals() -> void:
	var poly = get_node_or_null("Polygon2D")
	if not poly: return
	
	match enemy_type:
		"melee":
			poly.color = Color(1.0, 0.1, 0.1) * 3.5 # Laser Red
			scale = Vector2(1.0, 1.0)
		"ranged":
			poly.color = Color(1.0, 0.6, 0.0) * 3.5 # Laser Orange
			scale = Vector2(0.85, 0.85)
			shoot_range = 400.0
		"turret":
			poly.color = Color(0.8, 0.1, 1.0) * 3.5 # Laser Purple
			scale = Vector2(1.2, 1.2)
			aggro_range = 500.0
		"patrol":
			poly.color = Color(0.0, 1.0, 0.4) * 3.5 # Deep Emerald Green
			scale = Vector2(0.9, 0.9)

func _physics_process(delta: float) -> void:
	if _is_dead or not _player:
		return
	
	_melee_timer -= delta
	_shoot_timer -= delta

	var dist_to_player = global_position.distance_to(_player.global_position)
	if dist_to_player < aggro_range:
		_is_aggroed = true
	
	# If not aggroed, turrets and melee/ranged just wait (patrol keeps patrolling)
	if not _is_aggroed and enemy_type != "patrol":
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match enemy_type:
		"melee":
			_melee_behaviour(delta)
		"ranged":
			_ranged_behaviour(delta)
		"turret":
			_turret_behaviour(delta)
		"patrol":
			_patrol_behaviour(delta)
	
	_apply_separation()
	move_and_slide()

func _apply_separation() -> void:
	if enemy_type == "turret": return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var push_vector = Vector2.ZERO
	var separation_dist = 40.0
	
	for e in enemies:
		if e == self or not is_instance_valid(e): continue
		var dist = global_position.distance_to(e.global_position)
		if dist < separation_dist:
			var force = (separation_dist - dist) / separation_dist
			push_vector += e.global_position.direction_to(global_position) * force * 400.0
	
	velocity += push_vector

func _melee_behaviour(_delta: float) -> void:
	look_at(_player.global_position)
	var dist = global_position.distance_to(_player.global_position)
	
	if dist <= melee_range:
		velocity = Vector2.ZERO
		if _melee_timer <= 0.0:
			_melee_attack()
			_melee_timer = melee_cooldown
	else:
		nav_agent.target_position = _player.global_position
		if nav_agent.is_navigation_finished():
			velocity = Vector2.ZERO
		else:
			var next_path_pos = nav_agent.get_next_path_position()
			var dir = global_position.direction_to(next_path_pos)
			velocity = dir * move_speed

func _ranged_behaviour(_delta: float) -> void:
	look_at(_player.global_position)
	var dist = global_position.distance_to(_player.global_position)
	var desired_dist = shoot_range * 0.7
	
	if dist > desired_dist + 30.0:
		nav_agent.target_position = _player.global_position
		var next_path_pos = nav_agent.get_next_path_position()
		velocity = global_position.direction_to(next_path_pos) * ranged_stalk_speed
	elif dist < desired_dist - 30.0:
		# Simple back away
		velocity = global_position.direction_to(_player.global_position) * -ranged_stalk_speed
	else:
		velocity = Vector2.ZERO
	
	if dist <= shoot_range and _shoot_timer <= 0.0:
		_shoot_at_player()
		_shoot_timer = shoot_cooldown

func _turret_behaviour(_delta: float) -> void:
	look_at(_player.global_position)
	var dist = global_position.distance_to(_player.global_position)
	if dist <= shoot_range and _shoot_timer <= 0.0:
		_shoot_at_player()
		_shoot_timer = shoot_cooldown

func _patrol_behaviour(_delta: float) -> void:
	var target = _patrol_target if _going_to_target else _start_pos
	
	# If aggroed, maybe we stop patrolling and chase? 
	# For now, let's keep patrol but shoot if close.
	var dist_to_player = global_position.distance_to(_player.global_position)
	
	if _is_aggroed and dist_to_player < shoot_range:
		look_at(_player.global_position)
		if _shoot_timer <= 0.0:
			_shoot_at_player()
			_shoot_timer = shoot_cooldown
	else:
		look_at(target)
	
	nav_agent.target_position = target
	if nav_agent.is_navigation_finished():
		_going_to_target = !_going_to_target
		velocity = Vector2.ZERO
	else:
		var next_path_pos = nav_agent.get_next_path_position()
		velocity = global_position.direction_to(next_path_pos) * move_speed

func _melee_attack() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(time_damage)
	_flash(Color.RED)

func _shoot_at_player() -> void:
	if not _projectile_scene: return
	var dir = global_position.direction_to(_player.global_position)
	var proj = _projectile_scene.instantiate() as Node2D
	get_parent().add_child(proj)
	proj.global_position = global_position + dir * 20.0
	if "time_damage" in proj:
		proj.time_damage = time_damage
	if proj.has_method("launch"):
		proj.launch(dir * 280.0)
	_flash(Color.ORANGE)

func _flash(color: Color) -> void:
	var poly = get_node_or_null("Polygon2D")
	if not poly: return
	var tw = create_tween()
	tw.tween_property(poly, "modulate", color, 0.05)
	tw.tween_property(poly, "modulate", Color.WHITE, 0.1)

func hit_by_bullet() -> void:
	if _is_dead: return
	die()

func die() -> void:
	_is_dead = true
	if _blood_scene:
		var blood = _blood_scene.instantiate()
		get_parent().add_child(blood)
		blood.global_position = global_position
	if _game:
		_game.enemy_killed()
	queue_free()
