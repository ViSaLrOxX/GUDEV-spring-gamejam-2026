extends Node
@onready var audio : AudioStreamPlayer = $AudioStreamPlayer
func _ready() -> void:
    if audio:
        audio.play()
    var t := get_tree().create_timer(2.0)
    await t.timeout
    queue_free()
