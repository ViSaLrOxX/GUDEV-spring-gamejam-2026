extends Node

# Use load() instead of preload() to prevent compile-time crashes if files are missing
var sounds = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_sounds()
	_create_pool()

func _load_sounds() -> void:
	var sfx_path = "res://assets/sound_effects/"
	var to_load = {
		"shoot": "laserShoot.mp3",
		"hit": "hitHurt.wav",
		"pickup": "pickup.mp3",
		"click": "click.mp3",
		"explosion": "explosion.mp3"
	}
	
	for key in to_load:
		var full_path = sfx_path + to_load[key]
		if FileAccess.file_exists(full_path):
			sounds[key] = load(full_path)
		else:
			print("[AudioManager] Missing asset: ", full_path)
			sounds[key] = null

var _pool_size = 16
var _pool = []
var _next_player = 0
var _master_volume = 1.0

func _create_pool() -> void:
	for i in range(_pool_size):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

func set_volume(value: float) -> void:
	_master_volume = clampf(value, 0.0, 1.0)
	var db = linear_to_db(_master_volume)
	for p in _pool:
		p.volume_db = db

func get_volume() -> float:
	return _master_volume

func play_sfx(sound_name: String, pitch_rng: float = 0.1) -> void:
	if not sounds.has(sound_name) or sounds[sound_name] == null:
		print("[AudioManager] Cannot play: ", sound_name)
		return
		
	var player = _pool[_next_player]
	player.stream = sounds[sound_name]
	player.volume_db = linear_to_db(_master_volume)
	player.pitch_scale = randf_range(1.0 - pitch_rng, 1.0 + pitch_rng)
	player.play()
	# print("[AudioManager] Playing: ", sound_name)
	
	_next_player = (_next_player + 1) % _pool_size

func stop_all() -> void:
	for p in _pool:
		p.stop()
