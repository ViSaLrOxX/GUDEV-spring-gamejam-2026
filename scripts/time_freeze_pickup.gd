extends Area2D
const TIME_BONUS : float = 15.0
var _spin_time : float = 0.0
func _process(delta: float) -> void:
    _spin_time += delta
    rotation    = sin(_spin_time * 2.5) * 0.4
    scale = Vector2.ONE * (1.0 + 0.15 * sin(_spin_time * 5.0))
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        var game := get_tree().get_first_node_in_group("game")
        if game and game.has_method("collect_time_freeze"):
            game.collect_time_freeze(TIME_BONUS)
        queue_free()
