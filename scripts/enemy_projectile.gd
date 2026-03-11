extends Area2D
var _velocity : Vector2 = Vector2.ZERO
func launch(vel: Vector2) -> void:
    _velocity = vel
func _physics_process(delta: float) -> void:
    global_position += _velocity * delta
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and body.has_method("take_damage"):
        body.take_damage()
    queue_free()
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()
