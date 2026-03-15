extends CharacterBody2D

const CharacterData = preload("res://scripts/character_data.gd")

var move_speed       : float = 130.0
var acceleration     : float = 1200.0
var friction         : float = 800.0
var shoot_cooldown   : float = 0.3
var bullet_speed     : float = 600.0
var dash_speed       : float = 800.0
var dash_duration    : float = 0.15
var dash_cost        : float = 3.0
var dash_cooldown    : float = 0.8

var _shoot_timer     : float = 0.0
var _is_moving       : bool  = false
var _is_shooting     : bool  = false
var _dash_timer      : float = 0.0
var _dash_cd_timer   : float = 0.0
var _dash_dir        : Vector2 = Vector2.ZERO
var _is_dashing      : bool  = false
var _dash_invincible : bool  = false

var ability_charge    : float = 0.0
var ability_max       : float = 100.0
var _ability_ready    : bool  = false
var _was_ability_ready: bool  = false
var _ability_type     : String = "none"
var _free_shoot_timer : float = 0.0
var _char_colour      : Color = Color(0.2, 0.8, 1.0)
var _distance_moved   : float = 0.0

var _ghost_timer      : float = 0.0
const GHOST_INTERVAL  : float = 0.06

var _bullet_scene    : PackedScene = null
var _game            : Node2D = null

func _ready() -> void:
	add_to_group("player")
	_game = get_tree().get_first_node_in_group("game")
	_bullet_scene = load("res://scenes/bullet.tscn")

	var gs: Node  = get_node_or_null("/root/GameState")
	var char_id: String = gs.selected_character if gs else "VECTOR"
	var cdata: Dictionary = CharacterData.get_by_id(char_id)

	_ability_type = cdata["ability_type"]
	_char_colour  = cdata["colour"]
	move_speed   *= cdata["speed_mult"]
	acceleration *= cdata["speed_mult"]
	friction     *= cdata["speed_mult"]
	scale = Vector2(1.1, 1.1)

	var poly := get_node_or_null("Polygon2D")
	if poly:
		poly.color = _char_colour * 4.0

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

		var weight = _dash_timer / dash_duration
		velocity = _dash_dir * dash_speed * (0.4 + 0.6 * weight)
		_tick_ghost(delta, true)
		if _dash_timer <= 0.0:
			_is_dashing      = false
			_dash_invincible = false

			velocity = _dash_dir * move_speed * 1.2
	else:
		if _is_moving:
			velocity = velocity.move_toward(dir * move_speed, acceleration * delta)
			_tick_ghost(delta, false)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

		if Input.is_action_just_pressed("dash") and _dash_cd_timer <= 0.0 and _is_moving:
			_start_dash(dir)

	move_and_slide()
	look_at(get_global_mouse_position())

	_shoot_timer  -= delta
	_is_shooting   = false
	if _free_shoot_timer > 0.0:
		_free_shoot_timer -= delta
	if Input.is_action_pressed("shot") and _shoot_timer <= 0.0 and not _is_dashing:
		_shoot()

	if _game:
		_game.set_player_active(_is_moving or _is_shooting or _is_dashing)

	_tick_ability(delta)

	if _ability_ready and Input.is_action_just_pressed("ability"):
		_trigger_ability()

func enemy_killed_reward() -> void:
	if _ability_type == "bullet_time" or _ability_type == "time_heist":
		ability_charge = minf(ability_charge + 20.0, ability_max)
		if _game and _game.has_method("update_ability_bar"):
			_game.update_ability_bar(ability_charge, ability_max, ability_charge >= ability_max, _char_colour)

func _tick_ability(delta: float) -> void:
	if _ability_type == "none":
		return
	match _ability_type:
		"bullet_time":

			pass
		"invisibility":

			pass
		"wipeout":
			if _is_moving:

				_distance_moved += velocity.length() * delta
				ability_charge = minf(_distance_moved * 0.1, ability_max)
		"restore":
			if _game:
				var t: float = _game.get("time_remaining") if _game.get("time_remaining") != null else 60.0
				if t < 20.0:
					ability_charge = minf(ability_charge + delta * 18.0, ability_max)
		"free_shoot":
			ability_charge = minf(ability_charge + delta * 8.0, ability_max)
		"time_heist":

			pass
		"stasis":

			ability_charge = minf(ability_charge + delta * 4.0, ability_max)
		"sync_blast":

			pass

	_ability_ready = ability_charge >= ability_max
	if _game and _game.has_method("update_ability_bar"):
		_game.update_ability_bar(ability_charge, ability_max, _ability_ready, _char_colour)
	if _ability_ready and not _was_ability_ready:
		_game._show_big_bonus_message("ABILITY READY  [ E ]")
		_tween_flash(Color(1.0, 1.0, 0.3))
	_was_ability_ready = _ability_ready

func _trigger_ability() -> void:
	ability_charge  = 0.0
	_ability_ready  = false
	_distance_moved = 0.0
	match _ability_type:
		"bullet_time":
			if _game:
				_game.trigger_bullet_time(4.0)
		"invisibility":
			if _game:
				_game.trigger_invisibility(5.0)
		"wipeout":
			if _game:
				_game.trigger_purge_wipeout()
		"restore":
			if _game:
				_game.add_time(99.0)
				_game.trigger_screen_shake(0.3, 12.0)
				_game._show_big_bonus_message("SYSTEM RESTORED")
		"free_shoot":
			_free_shoot_timer = 6.0
			if _game:
				_game._show_big_bonus_message("FREE FIRE 6s")
		"time_heist":
			if _game:
				_game.trigger_bullet_time(6.0)
				_game.add_time(20.0)
				_game._show_big_bonus_message("TIME HEIST: +20s STOLEN")
		"stasis":
			if _game:
				_game.trigger_stasis(3.0)
		"sync_blast":
			if _game:
				_game.trigger_sync_blast()

func take_damage_on_ability_fill(amount: float) -> void:
	if _ability_type == "invisibility":
		ability_charge = minf(ability_charge + amount * 4.5, ability_max)
		if _game and _game.has_method("update_ability_bar"):
			_game.update_ability_bar(ability_charge, ability_max, ability_charge >= ability_max, _char_colour)
	elif _ability_type == "sync_blast":
		ability_charge = minf(ability_charge + amount * 6.0, ability_max)
		if _game and _game.has_method("update_ability_bar"):
			_game.update_ability_bar(ability_charge, ability_max, ability_charge >= ability_max, _char_colour)

func take_damage(amount: float = 8.0) -> void:
	if _dash_invincible:
		return
	if _game:
		_game.player_hit(amount)
	take_damage_on_ability_fill(amount)
	_tween_flash(Color.RED)

func _start_dash(dir: Vector2) -> void:
	_is_dashing      = true
	_dash_invincible = true
	_dash_timer      = dash_duration
	_dash_cd_timer   = dash_cooldown
	_dash_dir        = dir.normalized()
	if _game:
		_game.subtract_time(dash_cost)
	_tween_flash(Color(0.5, 0.8, 1.0))
	_spawn_dash_burst()

func _tick_ghost(delta: float, dashing: bool) -> void:
	_ghost_timer -= delta
	var interval = GHOST_INTERVAL * 0.4 if dashing else GHOST_INTERVAL
	if _ghost_timer <= 0.0:
		_ghost_timer = interval
		_spawn_ghost(dashing)

func _spawn_ghost(dashing: bool) -> void:
	var ghost = Polygon2D.new()
	var source = get_node_or_null("Polygon2D")
	if not source: return
	ghost.polygon = source.polygon
	ghost.global_position = global_position
	ghost.global_rotation = global_rotation
	ghost.scale = scale
	ghost.color = _char_colour * (3.0 if dashing else 1.5)
	ghost.z_index = z_index - 1

	get_parent().add_child(ghost)

	var tw = create_tween().set_parallel(true)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.25 if dashing else 0.15)
	tw.tween_property(ghost, "scale", scale * 0.8, 0.2)
	tw.finished.connect(ghost.queue_free)

func _spawn_dash_burst() -> void:
	for i in range(8):
		var ang = (PI * 2 / 8) * i
		var dir = Vector2.from_angle(ang)
		var ghost = Polygon2D.new()
		var source = get_node_or_null("Polygon2D")
		if not source: continue
		ghost.polygon = source.polygon
		ghost.global_position = global_position
		ghost.scale = scale * 0.4
		ghost.color = _char_colour * 2.0
		get_parent().add_child(ghost)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(ghost, "global_position", global_position + dir * 60.0, 0.3)
		tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
		tw.tween_property(ghost, "scale", Vector2.ZERO, 0.3)
		tw.finished.connect(ghost.queue_free)

func _shoot() -> void:
	if not _bullet_scene:
		return
	_shoot_timer = shoot_cooldown
	_is_shooting  = true

	var mouse_pos  := get_global_mouse_position()
	var shoot_dir  := global_position.direction_to(mouse_pos)

	var is_lethal  := false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + shoot_dir * 1200.0)
	query.collision_mask = 2
	var result := space_state.intersect_ray(query)
	if result and result.collider and result.collider.is_in_group("enemies"):
		is_lethal = true

	var bullet := _bullet_scene.instantiate() as Node2D
	get_parent().add_child(bullet)

	var spawn_pos := global_position + shoot_dir * 20.0
	var marker    := get_node_or_null("BulletSpawn")
	if marker:
		spawn_pos = marker.global_position
	bullet.global_position = spawn_pos
	bullet.rotation        = global_rotation
	if bullet.has_method("launch"):
		bullet.launch(shoot_dir * bullet_speed)

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("shoot")

	var flash := ColorRect.new()
	flash.color = _char_colour * 4.0
	flash.size = Vector2(12, 12)
	flash.pivot_offset = Vector2(6, 6)
	var spawn_pos2 := global_position
	var marker2 := get_node_or_null("BulletSpawn")
	if marker2: spawn_pos2 = marker2.global_position
	flash.global_position = spawn_pos2 - Vector2(6, 6)
	get_parent().add_child(flash)
	var ftw := flash.create_tween().set_parallel(true)
	ftw.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.08)
	ftw.tween_property(flash, "modulate:a", 0.0, 0.1)
	ftw.finished.connect(flash.queue_free)

	if _game:
		if _free_shoot_timer > 0.0:
			_game.player_shoot(true)
		else:
			_game.player_shoot(is_lethal)

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
