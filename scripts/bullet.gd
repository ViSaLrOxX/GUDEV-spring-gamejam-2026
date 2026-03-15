extends Area2D

var _velocity      : Vector2 = Vector2.ZERO
var _particle_scene: PackedScene = null
var _trail         : Line2D
var is_critical    : bool = false

func _ready() -> void:
	add_to_group("player_bullets")
	_particle_scene = load("res://scenes/bullet_particle.tscn")
	area_entered.connect(_on_area_entered)

	is_critical = randf() < 0.15

	var poly = get_node_or_null("Polygon2D")
	if poly:
		if is_critical:
			poly.color = Color(1.0, 0.3, 0.0) * 8.0
			scale = Vector2(1.6, 1.6)
		else:
			poly.color = Color(1.0, 1.0, 0.6) * 5.0

	_trail = Line2D.new()
	_trail.width = 5.0 if is_critical else 3.0
	_trail.default_color = Color(1.0, 0.4, 0.0, 0.6) if is_critical else Color(1.0, 1.0, 0.5, 0.4)
	_trail.top_level = true
	add_child(_trail)
	_trail.add_point(global_position)
	_trail.add_point(global_position)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_projectiles"):
		_spawn_particle()
		area.queue_free()
		queue_free()

func launch(vel: Vector2) -> void:
	_velocity = vel

func _physics_process(delta: float) -> void:
	var prev_pos = global_position
	global_position += _velocity * delta
	if _trail:
		_trail.set_point_position(0, global_position)
		_trail.set_point_position(1, prev_pos)

func _on_body_entered(body: Node2D) -> void:
	_spawn_particle()
	if body.has_method("hit_by_bullet"):
		if is_critical:

			body.hit_by_bullet()
			body.hit_by_bullet()
			body.hit_by_bullet()

			var game = get_tree().get_first_node_in_group("game")
			if game and game.has_method("spawn_world_label"):
				game.spawn_world_label(global_position, "CRITICAL!", Color(1.0, 0.4, 0.0))
		else:
			body.hit_by_bullet()
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _spawn_particle() -> void:
	if not _particle_scene:
		return
	var p := _particle_scene.instantiate()
	get_parent().add_child(p)
	p.global_position = global_position
