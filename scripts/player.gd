extends CharacterBody2D

var move_speed      : float = 130.0
var shoot_cooldown  : float = 0.3
var bullet_speed    : float = 600.0
var dash_speed      : float = 600.0
var dash_duration   : float = 0.15
var dash_cost       : float = 3.0
var dash_cooldown   : float = 1.0

var _shoot_timer    : float = 0.0
var _is_moving      : bool  = false
var _is_shooting    : bool  = false
var _dash_timer     : float = 0.0
var _dash_cd_timer  : float = 0.0
var _dash_dir       : Vector2 = Vector2.ZERO
var _is_dashing     : bool  = false
var _dash_invincible: bool  = false

var _bullet_scene   : PackedScene = null
var _game           : Node2D = null

func _ready() -> void:
	add_to_group("player")
	_game = get_tree().get_first_node_in_group("game")
	_bullet_scene = load("res://scenes/bullet.tscn")
	scale = Vector2(1.1, 1.1)
	
	var poly = get_node_or_null("Polygon2D")
	if poly:
		poly.color = Color(1.5, 1.5, 2.0) * 4.0 # Brilliant White-Blue Super-Nova

func _physics_process(delta: float) -> void:
	if not _game:
		_game = get_tree().get_first_node_in_group("game")
	
	if _game and not _game.game_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var dir := _get_input_direction()
	_is_moving = dir.length_squared() > 0.01

	_dash_cd_timer -= delta
	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_dir * dash_speed
		if _dash_timer <= 0.0:
			_is_dashing      = false
			_dash_invincible = false
	else:
		velocity = dir * move_speed
		if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0 and _is_moving:
			_start_dash(dir)

	move_and_slide()
	look_at(get_global_mouse_position())

	_shoot_timer -= delta
	_is_shooting  = false
	if Input.is_action_pressed("shot") and _shoot_timer <= 0.0 and not _is_dashing:
		_shoot()

	if _game:
		_game.set_player_active(_is_moving or _is_shooting or _is_dashing)

func _start_dash(dir: Vector2) -> void:
	_is_dashing      = true
	_dash_invincible = true
	_dash_timer      = dash_duration
	_dash_cd_timer   = dash_cooldown
	_dash_dir        = dir.normalized()
	if _game:
		_game.subtract_time(dash_cost)
	_tween_flash(Color(0.5, 0.8, 1.0))

func _shoot() -> void:
	if not _bullet_scene:
		return
	_shoot_timer = shoot_cooldown
	_is_shooting  = true
	
	var mouse_pos = get_global_mouse_position()
	var shoot_dir = global_position.direction_to(mouse_pos)
	
	# Lethal Intent Raycast
	var is_lethal = false
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + shoot_dir * 1200.0)
	query.collision_mask = 2 # Enemies
	var result = space_state.intersect_ray(query)
	if result and result.collider and result.collider.is_in_group("enemies"):
		is_lethal = true

	var bullet := _bullet_scene.instantiate() as Node2D
	get_parent().add_child(bullet)
	
	var spawn_pos = global_position + shoot_dir * 20.0
	var marker = get_node_or_null("BulletSpawn")
	if marker:
		spawn_pos = marker.global_position
		
	bullet.global_position = spawn_pos
	bullet.rotation        = global_rotation
	if bullet.has_method("launch"):
		bullet.launch(shoot_dir * bullet_speed)
	if _game:
		_game.player_shoot(is_lethal)

func take_damage(amount: float = 8.0) -> void:
	if _dash_invincible:
		return
	if _game:
		_game.player_hit(amount)
	_tween_flash(Color.RED)

func _get_input_direction() -> Vector2:
	var d := Vector2.ZERO
	d.x = Input.get_axis("move_left", "move_right")
	d.y = Input.get_axis("move_up",   "move_down")
	return d.normalized()

func _tween_flash(color: Color) -> void:
	var poly := get_node_or_null("Polygon2D")
	if not poly:
		return
	var tw := create_tween()
	tw.tween_property(poly, "modulate", color,       0.06)
	tw.tween_property(poly, "modulate", Color.WHITE,  0.14)
