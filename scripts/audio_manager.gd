extends Node

var sounds = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_sounds()
	_create_pool()
	_setup_music_player()

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
var _music_volume = 0.2
var _sfx_volumes = {
	"shoot": 0.6,
	"hit": 0.6,
	"pickup": 0.6,
	"click": 0.6,
	"explosion": 0.1
}
var _music_player : AudioStreamPlayer

func _create_pool() -> void:
	for i in range(_pool_size):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

func play_music(file_name: String) -> void:
	var path = "res://assets/music/" + file_name
	if FileAccess.file_exists(path):
		var stream = load(path)
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(_music_volume * _master_volume)
		_music_player.play()
	else:
		print("[AudioManager] Music file not found: ", path)

func set_master_volume(val: float) -> void:
	_master_volume = clampf(val, 0.0, 1.0)
	_update_all_volumes()

func set_music_volume(val: float) -> void:
	_music_volume = clampf(val, 0.0, 1.0)
	_update_all_volumes()

func set_sfx_volume(sound_name: String, val: float) -> void:
	if _sfx_volumes.has(sound_name):
		_sfx_volumes[sound_name] = clampf(val, 0.0, 1.0)

func get_master_volume() -> float: return _master_volume
func get_music_volume() -> float: return _music_volume
func get_sfx_volume(sound_name: String) -> float: return _sfx_volumes.get(sound_name, 1.0)

func _update_all_volumes() -> void:
	if _music_player:
		_music_player.volume_db = linear_to_db(_music_volume * _master_volume)

func play_sfx(sound_name: String, pitch_rng: float = 0.1) -> void:
	if not sounds.has(sound_name) or sounds[sound_name] == null:
		print("[AudioManager] Cannot play: ", sound_name)
		return

	var player = _pool[_next_player]
	player.stream = sounds[sound_name]

	var sfx_val = _sfx_volumes.get(sound_name, 1.0)
	player.volume_db = linear_to_db(sfx_val * _master_volume)

	player.pitch_scale = randf_range(1.0 - pitch_rng, 1.0 + pitch_rng)
	player.play()

	_next_player = (_next_player + 1) % _pool_size

func stop_all() -> void:
	for p in _pool:
		p.stop()
