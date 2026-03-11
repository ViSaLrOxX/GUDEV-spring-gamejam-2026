extends CharacterBody2D

const MOVE_SPEED     : float = 200.0
const SHOOT_COOLDOWN : float = 0.3
const BULLET_SPEED   : float = 600.0
const DASH_SPEED     : float = 700.0
const DASH_DURATION  : float = 0.15
const DASH_COST      : float = 3.0
const DASH_COOLDOWN  : float = 1.0

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

func _physics_process(delta: float) -> void:
	var dir := _get_input_direction()
	_is_moving = dir.length_squared() > 0.01

	_dash_cd_timer -= delta
	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_dir * DASH_SPEED
		if _dash_timer <= 0.0:
			_is_dashing      = false
			_dash_invincible = false
	else:
		velocity = dir * MOVE_SPEED
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
	_dash_timer      = DASH_DURATION
	_dash_cd_timer   = DASH_COOLDOWN
	_dash_dir        = dir.normalized()
	if _game:
		_game.subtract_time(DASH_COST)
	_tween_flash(Color(0.5, 0.8, 1.0))

func _shoot() -> void:
	if not _bullet_scene:
		return
	_shoot_timer = SHOOT_COOLDOWN
	_is_shooting  = true
	var bullet := _bullet_scene.instantiate() as Node2D
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2.RIGHT.rotated(global_rotation) * 20.0
	bullet.rotation        = global_rotation
	if bullet.has_method("launch"):
		bullet.launch(Vector2.RIGHT.rotated(global_rotation) * BULLET_SPEED)
	if _game:
		_game.player_shoot()

func take_damage() -> void:
	if _dash_invincible:
		return
	if _game:
		_game.player_hit()
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
