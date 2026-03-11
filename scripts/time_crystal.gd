extends Area2D
var _rotation_speed : float = 1.2
var _pulse_time     : float = 0.0
func _process(delta: float) -> void:
    rotation     += _rotation_speed * delta
    _pulse_time  += delta
    scale = Vector2.ONE * (1.0 + 0.1 * sin(_pulse_time * 3.0))
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        var game := get_tree().get_first_node_in_group("game")
        if game:
            game.collect_core()
        queue_free()
