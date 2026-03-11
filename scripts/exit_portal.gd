extends Area2D

var _active  : bool  = false
var _spin    : float = 0.0

func _ready() -> void:
	modulate = Color(0.3, 0.0, 0.6, 0.4)

func _process(delta: float) -> void:
	if not _active:
		return
	_spin += delta
	var vis := get_node_or_null("Visual")
	if vis:
		vis.rotation = _spin * 1.5
		var inner := vis.get_node_or_null("Inner")
		if inner:
			inner.rotation = -_spin * 2.5
	modulate.a = 0.85 + 0.15 * sin(_spin * 6.0)

func activate() -> void:
	_active  = true
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.0, 0.4, 1.0, 1.0), 0.5)
	tw.tween_property(self, "modulate", Color(0.6, 0.0, 1.0, 1.0), 0.5)
	tw.set_loops()

func _on_body_entered(body: Node2D) -> void:
	if _active and body.is_in_group("player"):
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.portal_entered()
