extends Area2D

const WARP_DURATION : float = 3.0
var _spin_time       : float = 0.0

func _ready() -> void:
	var poly := get_node_or_null("Polygon2D")
	if poly:
		poly.color = Color(0.0, 1.0, 0.6) * 4.0

func _process(delta: float) -> void:
	_spin_time += delta
	rotation    = _spin_time * 2.0
	scale = Vector2.ONE * (1.0 + 0.2 * sin(_spin_time * 6.0))
	var poly := get_node_or_null("Polygon2D")
	if poly:
		poly.modulate = Color.WHITE * (1.5 + 0.5 * sin(_spin_time * 10.0))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("activate_time_warp"):
			game.activate_time_warp(WARP_DURATION)
		queue_free()
