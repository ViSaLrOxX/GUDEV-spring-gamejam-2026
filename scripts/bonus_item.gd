extends Area2D
var _bob_time : float = 0.0
var _start_y  : float = 0.0

func _ready() -> void:
	add_to_group("coins")
	_start_y = position.y

	var poly = get_node_or_null("Polygon2D")
	if poly:
		poly.color = Color(1.0, 0.85, 0.2) * 2.5

func _process(delta: float) -> void:
	_bob_time  += delta
	position.y  = _start_y + sin(_bob_time * 4.0) * 4.0
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("pickup")
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.collect_coin()
		queue_free()
