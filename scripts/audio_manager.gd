extends Node

# Dictionary to store preloaded sounds
var sounds = {
	"shoot": preload("res://assets/sound_effects/laserShoot.wav") if FileAccess.file_exists("res://assets/sound_effects/laserShoot.wav") else null,
	"hit": preload("res://assets/sound_effects/hitHurt.wav") if FileAccess.file_exists("res://assets/sound_effects/hitHurt.wav") else null,
	"explosion": null,
	"pickup": preload("res://assets/sound_effects/laserShoot.wav") if FileAccess.file_exists("res://assets/sound_effects/laserShoot.wav") else null, # Fallback
	"click": preload("res://assets/sound_effects/hitHurt.wav") if FileAccess.file_exists("res://assets/sound_effects/hitHurt.wav") else null # Fallback
}

var _pool_size = 16
var _pool = []
var _next_player = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Play sounds even when game is paused
	
	# Create a pool of audio players
	for i in range(_pool_size):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

func play_sfx(sound_name: String, pitch_rng: float = 0.1) -> void:
	if not sounds.has(sound_name) or sounds[sound_name] == null:
		return
		
	var player = _pool[_next_player]
	player.stream = sounds[sound_name]
	player.pitch_scale = randf_range(1.0 - pitch_rng, 1.0 + pitch_rng)
	player.play()
	
	_next_player = (_next_player + 1) % _pool_size

func stop_all() -> void:
	for p in _pool:
		p.stop()
