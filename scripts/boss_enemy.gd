extends CharacterBody2D

var max_hp            : int   = 3
var hp                : int   = 3
var move_speed        : float = 90.0
var shoot_cooldown    : float = 0.9
var charge_cooldown   : float = 4.0
var time_damage       : float = 15.0
var reward_multiplier : int   = 5

var _player           : Node2D = null
var _game             : Node2D = null
var _shoot_timer      : float  = 0.0
var _charge_timer     : float  = 0.0
var _is_dead          : bool   = false
var _is_charging      : bool   = false
var _charge_dir       : Vector2 = Vector2.ZERO
var _charge_duration  : float  = 0.0
var _pulse_time       : float  = 0.0

@onready var nav_agent      : NavigationAgent2D = $NavigationAgent2D
var _projectile_scene        : PackedScene = null
var _blood_scene             : PackedScene = null

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	_player = get_tree().get_first_node_in_group("player")
	_game   = get_tree().get_first_node_in_group("game")
	_projectile_scene = load("res://scenes/enemy_projectile.tscn")
	_blood_scene      = load("res://scenes/blood_particle.tscn")
	nav_agent.path_desired_distance  = 20.0
	nav_agent.target_desired_distance = 20.0
	_apply_phase_visuals()
	if _game and _game.has_method("trigger_screen_shake"):
		_game.trigger_screen_shake(0.4, 18.0)

func _apply_phase_visuals() -> void:
	var poly := get_node_or_null("Polygon2D")
	if not poly:
		return
	match hp:
		3: poly.color = Color(1.0, 0.0, 0.5) * 4.5
		2: poly.color = Color(1.0, 0.35, 0.0) * 4.5
		1: poly.color = Color(1.0, 1.0, 0.0) * 4.5
	scale = Vector2.ONE * (1.5 + (max_hp - hp) * 0.2)

func _physics_process(delta: float) -> void:
	if _is_dead or not _player:
		return
	_pulse_time   += delta
	_shoot_timer  -= delta
	_charge_timer -= delta

	var poly := get_node_or_null("Polygon2D")
	if poly:
		poly.modulate = Color.WHITE * (1.0 + 0.3 * sin(_pulse_time * 8.0))

	if _is_charging:
		_charge_duration -= delta
		velocity = _charge_dir * move_speed * 3.5
		if _charge_duration <= 0.0:
			_is_charging = false
		move_and_slide()
		_check_melee_hit()
		return

	look_at(_player.global_position)
	nav_agent.target_position = _player.global_position
	if not nav_agent.is_navigation_finished():
		velocity = global_position.direction_to(nav_agent.get_next_path_position()) * move_speed
	else:
		velocity = Vector2.ZERO

	if _shoot_timer <= 0.0:
		_shoot_burst()
		_shoot_timer = shoot_cooldown
	if _charge_timer <= 0.0 and hp <= 2:
		_begin_charge()
		_charge_timer = charge_cooldown

	move_and_slide()

func _shoot_burst() -> void:
	if not _projectile_scene:
		return
	var burst := 1 if hp == 3 else (2 if hp == 2 else 4)
	var base_dir := global_position.direction_to(_player.global_position)
	for i in range(burst):
		var spread := deg_to_rad((i - (burst - 1) / 2.0) * 20.0)
		var dir    := base_dir.rotated(spread)
		var proj   := _projectile_scene.instantiate() as Node2D
		get_parent().add_child(proj)
		proj.global_position = global_position + dir * 30.0
		if "time_damage" in proj:
			proj.time_damage = time_damage
		if proj.has_method("launch"):
			proj.launch(dir * 340.0)

func _begin_charge() -> void:
	_is_charging     = true
	_charge_dir      = global_position.direction_to(_player.global_position)
	_charge_duration = 0.35
	if _game:
		_game.trigger_screen_shake(0.15, 8.0)

func _check_melee_hit() -> void:
	if not _player:
		return
	if global_position.distance_to(_player.global_position) < 60.0:
		if _player.has_method("take_damage"):
			_player.take_damage(time_damage)
		_is_charging = false

func hit_by_bullet() -> void:
	if _is_dead:
		return
	hp -= 1
	if _game:
		_game.trigger_screen_shake(0.25, 22.0)
	if hp <= 0:
		die()
	else:
		_apply_phase_visuals()
		if _game and _game.has_method("_show_big_bonus_message"):
			_game._show_big_bonus_message("PHASE %d" % (max_hp - hp + 1))
		_flash(Color.WHITE)

func die() -> void:
	_is_dead = true
	if _blood_scene:
		for i in range(6):
			var b := _blood_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	if _game:
		# Count as one kill for the level wipeout progress
		_game.enemy_killed(true)
		# Add bonus rewards that don't count toward wipeout total
		for i in range(reward_multiplier - 1):
			_game.enemy_killed(false)
	queue_free()

func _flash(color: Color) -> void:
	var poly := get_node_or_null("Polygon2D")
	if not poly:
		return
	var tw := create_tween()
	tw.tween_property(poly, "modulate", color,      0.05)
	tw.tween_property(poly, "modulate", Color.WHITE, 0.1)
