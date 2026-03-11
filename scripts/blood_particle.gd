extends Node2D
func _ready() -> void:
    var t := get_tree().create_timer(1.5)
    await t.timeout
    queue_free()
