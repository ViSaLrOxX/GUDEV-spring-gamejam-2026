extends Area2D
var _bob_time : float = 0.0
func _ready() -> void:
	add_to_group("coins")
func _process(delta: float) -> void:
	_bob_time  += delta
	position.y  = sin(_bob_time * 4.0) * 3.0
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.collect_coin()
		queue_free()
