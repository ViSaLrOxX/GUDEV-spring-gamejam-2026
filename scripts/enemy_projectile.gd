extends Area2D
var _velocity : Vector2 = Vector2.ZERO
var time_damage : float = 8.0

func _ready() -> void:
	add_to_group("enemy_projectiles")
	area_entered.connect(_on_area_entered)
	
	var poly = get_node_or_null("Polygon2D")
	if poly:
		poly.visible = false # Hide square poly
	
	queue_redraw()

func _draw() -> void:
	var color = Color(1.0, 0.2, 0.2) * 3.0
	draw_circle(Vector2.ZERO, 6.0, color)
	# Inner core
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE * 2.0)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullets"):
		area.queue_free()
		queue_free()

func launch(vel: Vector2) -> void:
	_velocity = vel

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(time_damage)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
