extends Node2D

signal exit_requested

var frames: Array = []
var metadata: Dictionary = {}
var main_camera: Camera2D
var is_playing: bool = true
var current_time: float = 0.0
var max_time: float = 0.0
var playback_speed: float = 1.0

var ui_canvas: CanvasLayer
var time_slider: HSlider
var speed_label: Label
var time_label: Label

var player_poly := PackedVector2Array([Vector2(22, 0), Vector2(6, 6), Vector2(0, 22), Vector2(-6, 6), Vector2(-22, 0), Vector2(-6, -6), Vector2(0, -22), Vector2(6, -6)])
var enemy_poly := PackedVector2Array([Vector2(15, 0), Vector2(-15, 10), Vector2(-10, 0), Vector2(-15, -10)])

func setup(_frames: Array, _metadata: Dictionary, _camera: Camera2D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 0 
	frames = _frames
	metadata = _metadata
	main_camera = _camera
	if frames.size() > 0:
		max_time = frames[-1]["time"]
		current_time = frames[0]["time"]
	_build_ui()

func _build_ui() -> void:
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 110
	add_child(ui_canvas)
	
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -120
	var tech_bg = Color(0.01, 0.03, 0.05, 0.9)
	var p_style = StyleBoxFlat.new(); p_style.bg_color = tech_bg; p_style.border_width_top = 2; p_style.border_color = Color(0.2, 0.8, 1.0)
	panel.add_theme_stylebox_override("panel", p_style)
	ui_canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var top_hbox = HBoxContainer.new()
	vbox.add_child(top_hbox)
	
	time_label = Label.new()
	time_label.text = "0.0s / 0.0s"
	time_label.custom_minimum_size = Vector2(150, 0)
	top_hbox.add_child(time_label)
	
	time_slider = HSlider.new()
	time_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if frames.size() > 0:
		time_slider.min_value = frames[0]["time"]
		time_slider.max_value = max_time
	time_slider.step = 0.01
	time_slider.value_changed.connect(func(v): if not is_playing: current_time = v; queue_redraw())
	top_hbox.add_child(time_slider)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var btn_rw = Button.new(); btn_rw.text = "<< -1x"; btn_hbox.add_child(btn_rw)
	btn_rw.pressed.connect(func(): playback_speed = -1.0; speed_label.text = "SPD: -1x"; is_playing = true)
	
	var btn_play = Button.new(); btn_play.text = "PLAY/PAUSE"; btn_hbox.add_child(btn_play)
	btn_play.pressed.connect(func(): is_playing = not is_playing)
	
	var btn_fw = Button.new(); btn_fw.text = ">> 1x"; btn_hbox.add_child(btn_fw)
	btn_fw.pressed.connect(func(): playback_speed = 1.0; speed_label.text = "SPD: 1x"; is_playing = true)
	
	var btn_ffw = Button.new(); btn_ffw.text = ">> 2x"; btn_hbox.add_child(btn_ffw)
	btn_ffw.pressed.connect(func(): playback_speed = 2.0; speed_label.text = "SPD: 2x"; is_playing = true)
	
	speed_label = Label.new()
	speed_label.text = "SPD: 1x"
	btn_hbox.add_child(speed_label)
	
	var btn_exit = Button.new(); btn_exit.text = "[ TERMINATE REPLAY ]"
	btn_exit.modulate = Color(1.0, 0.4, 0.4)
	btn_exit.pressed.connect(func(): exit_requested.emit())
	btn_hbox.add_child(btn_exit)

func _process(delta: float) -> void:
	if is_playing and frames.size() > 0:
		current_time += delta * playback_speed
		if current_time > max_time:
			current_time = max_time
			is_playing = false
		elif current_time < frames[0]["time"]:
			current_time = frames[0]["time"]
			is_playing = false
			
		time_slider.set_value_no_signal(current_time)
		queue_redraw()
	
	if frames.size() > 0:
		time_label.text = "%.1fs / %.1fs" % [current_time, max_time]
		var frame = _get_frame_at(current_time)
		if frame and main_camera:
			main_camera.global_position = frame["cam_pos"]

func _draw() -> void:
	if frames.is_empty(): return
	var frame = _get_frame_at(current_time)
	if not frame: return
	
	# Draw Map BG
	if metadata.has("map_w"):
		var w = metadata["map_w"]
		var h = metadata["map_h"]
		draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.05, 0.07))
		# Rim
		draw_rect(Rect2(0, 0, w, 20), Color(0.2, 0.8, 1.0))
		draw_rect(Rect2(0, h-20, w, 20), Color(0.2, 0.8, 1.0))
		draw_rect(Rect2(0, 0, 20, h), Color(0.2, 0.8, 1.0))
		draw_rect(Rect2(w-20, 0, 20, h), Color(0.2, 0.8, 1.0))
		
	# Draw Walls
	if metadata.has("walls"):
		for rect in metadata["walls"]:
			draw_rect(rect, Color(0.1, 0.1, 0.15))
			draw_rect(rect, Color(0.2, 0.8, 1.0), false, 1.0) # Outline
	
	# Draw Entities
	for ent in frame["ents"]:
		var t = ent[0]
		var pos = Vector2(ent[1], ent[2])
		var rot = ent[3]
		var sc = Vector2(ent[4], ent[5])
		var col = Color(ent[6], ent[7], ent[8], ent[9])
		
		draw_set_transform(pos, rot, sc)
		if t == 0:
			draw_polygon(player_poly, [col])
		elif t == 1:
			draw_polygon(enemy_poly, [col])
		elif t == 2:
			draw_circle(Vector2.ZERO, 3.0, col)
		elif t == 3:
			draw_rect(Rect2(-6, -6, 12, 12), col)
			
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _get_frame_at(t: float) -> Dictionary:
	if frames.is_empty(): return {}
	if t <= frames[0]["time"]: return frames[0]
	if t >= frames[-1]["time"]: return frames[-1]
	
	var last_f = frames[0]
	for f in frames:
		if f["time"] > t:
			return last_f
		last_f = f
	return frames[-1]
