extends Node2D

const SLOW_TIME_SCALE  : float = 0.05
const NORMAL_TIME_SCALE: float = 1.0
const TIME_LERP_SPEED  : float = 15.0
const STARTING_TIME    : float = 30.0
const BASE_SHOOT_COST  : float = 5.0 
const HIT_COST         : float = 12.0
const BASE_KILL_REWARD : float = 6.0
const COMBO_WINDOW     : float = 3.0
const MAX_COMBO        : int   = 4

var current_level     : int   = 1
var time_remaining    : float = STARTING_TIME
var cores_required    : int   = 5
var cores_collected   : int   = 0
var coins_collected   : int   = 0
var total_coins       : int   = 0
var total_enemies_killed : int = 0
var total_coins_collected : int = 0
var total_time_elapsed : float = 0.0
var enemies_killed_in_level : int = 0
var total_enemies_in_level : int = 0
var portal_unlocked   : bool  = false
var game_active       : bool  = true
var target_time_scale : float = SLOW_TIME_SCALE
var _last_real_ms     : int   = 0
var combo_count       : int   = 0
var combo_timer       : float = 0.0
var shake_duration    : float = 0.0
var shake_strength    : float = 0.0

var _is_dying          : bool  = false
var _death_grace_timer : float = 0.0
const DEATH_GRACE_TIME : float = 0.4
var _is_transitioning  : bool  = false
var _transition_tween  : Tween = null
var _ghost_check_timer : float = 0.0

var _shot_heat_multiplier : int = 0
var _last_shot_time_ms : int = 0
const HEAT_WINDOW_MS : int = 1000

var inventory : Array = []
var is_waiting_to_start : bool = true
var is_shop_open : bool = false
var is_settings_open : bool = false
var _transition_lock_timer : float = 0.0
const TRANSITION_DELAY : float = 0.8
var _was_moving_on_load : bool = true

const BASE_ZOOM : float = 1.5 
var _target_zoom : float = BASE_ZOOM
var _zoom_speed : float = 10.0

@onready var camera        : Camera2D = get_node_or_null("Camera2D")
@onready var player        : CharacterBody2D = get_node_or_null("Player")
@onready var bg            : ColorRect = get_node_or_null("Background")
@onready var nav_region    : NavigationRegion2D = get_node_or_null("NavigationRegion2D")

var time_bar : ProgressBar
var cooldown_bar : ProgressBar
var progress_bar : ProgressBar
var coins_bank_label : Label
var level_label : Label
var combo_label : Label
var shop_hint_label : Label
var enemies_remaining_label : Label
var inventory_label : Label
var ability_bar : ProgressBar
var ability_bar_label : Label
var fade_overlay : ColorRect

var portal_scene     = preload("res://scenes/exit_portal.tscn")
var enemy_scene      = preload("res://scenes/enemy.tscn")
var crystal_scene    = preload("res://scenes/time_crystal.tscn")
var coin_scene       = preload("res://scenes/bonus_item.tscn")
var time_freeze_scene = preload("res://scenes/time_freeze_pickup.tscn")
var boss_scene       = preload("res://scenes/boss_enemy.tscn")
var time_warp_scene  = preload("res://scenes/time_warp_pickup.tscn")

var _time_warp_active  : bool  = false
var _time_warp_timer   : float = 0.0
var _boss_this_level   : bool  = false
var _enemy_speed_mult  : float = 1.0
var player_invisible   : bool  = false
var _invisible_timer   : float = 0.0
var _bullet_time_active : bool = false
var _bullet_time_timer  : float = 0.0

var portal_instance: Node2D = null
var dynamic_entities: Node2D = null
var dynamic_walls: Node2D = null

var minimap_view : SubViewport
var minimap_cam : Camera2D

var _replay_frames: Array = []
var _replay_metadata: Dictionary = {}
var _replay_record_timer: float = 0.0
const REPLAY_RECORD_RATE: float = 1.0 / 30.0

var _game_mode : String = "normal"
var _tutorial_step : int = 0
var _tut_label : Label
var _tut_instruction : Label
var _tut_timer : float = 0.0
var _range_respawn_timer : float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game")
	var gs: Node = get_node_or_null("/root/GameState")
	if gs:
		var cdata: Dictionary = (preload("res://scripts/character_data.gd") as GDScript).get_by_id(gs.selected_character)
		_enemy_speed_mult = cdata["enemy_speed_mult"]
		_game_mode = gs.game_mode
	
	dynamic_entities = Node2D.new(); dynamic_entities.process_mode = Node.PROCESS_MODE_PAUSABLE; add_child(dynamic_entities)
	dynamic_walls = Node2D.new(); dynamic_walls.process_mode = Node.PROCESS_MODE_PAUSABLE; add_child(dynamic_walls)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_music("music.mp3")
	_setup_screen_shader()
	_setup_overscreen_hud()
	
	# Defer start to ensure HUD and Shaders are fully ready
	call_deferred("_initialize_mode")

func _initialize_mode() -> void:
	if _game_mode == "tutorial":
		_setup_tutorial_ui()
		_start_tutorial_sequence()
	elif _game_mode == "range":
		_start_range_sequence()
	else:
		_clear_static_nodes()
		_start_level(1, false)

func _setup_tutorial_ui() -> void:
	var root = get_node_or_null("UI/HudRoot")
	if not root: return
	var tut_panel = PanelContainer.new(); tut_panel.name = "TutorialPanel"; tut_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP); tut_panel.offset_top = 180; tut_panel.custom_minimum_size = Vector2(650, 0); root.add_child(tut_panel)
	var style = StyleBoxFlat.new(); style.bg_color = Color(0.01, 0.03, 0.05, 0.85); style.border_width_left = 3; style.border_color = Color(0.2, 0.8, 1.0); style.content_margin_left = 25; style.content_margin_right = 25; style.content_margin_top = 20; style.content_margin_bottom = 20; tut_panel.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 10); tut_panel.add_child(vbox)
	_tut_label = Label.new(); _tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _tut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _tut_label.add_theme_font_size_override("font_size", 24); _tut_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0) * 2.0); vbox.add_child(_tut_label)
	_tut_instruction = Label.new(); _tut_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _tut_instruction.add_theme_font_size_override("font_size", 16); _tut_instruction.modulate = Color.GRAY; vbox.add_child(_tut_instruction)

func _start_tutorial_sequence() -> void:
	current_level = 0; is_waiting_to_start = false; _clear_static_nodes()
	var map_w = 1200.0; var map_h = 800.0; _rebuild_boundaries(map_w, map_h); _rebuild_navigation(map_w, map_h, [])
	if player: player.visible = true; player.global_position = Vector2(map_w/2, map_h/2); player.process_mode = Node.PROCESS_MODE_PAUSABLE
	if shop_hint_label: shop_hint_label.visible = false
	cores_collected = 0; enemies_killed_in_level = 0; portal_unlocked = false; game_active = true; _replay_frames.clear()
	_tutorial_step = 0; _advance_tutorial()

func _advance_tutorial() -> void:
	_tutorial_step += 1
	match _tutorial_step:
		1: _set_tut_text("SYSTEM_INITIATED. ID: VECTOR.\nWelcome to the Chrono-Simulation.", "[ PRESS WASD TO MOVE ]")
		2: _set_tut_text("TIME IS FRACTURED.\nIt only flows when you move.\nStabilize the stream.", "[ CONTINUE MOVING TO SYNC ]"); _tut_timer = 1.5
		3: _set_tut_text("TACTICAL OVERLAY ACTIVATED.\nShift to DASH. It costs stability (time)\nbut allows for rapid repositioning.", "[ PRESS SHIFT TO DASH ]")
		4: _set_tut_text("HOSTILE ENTITY DETECTED.\nLeft Click to PURGE.\nLethal shots reward stability.", "[ ELIMINATE THE TARGET ]"); _spawn_tut_entity("enemy")
		5: _set_tut_text("TIME CORES RECOVERED.\nCollect them to unlock the Exit Portal.", "[ RETRIEVE THE CORE ]"); _spawn_tut_entity("core")
		6: _set_tut_text("PORTAL STABILIZED.\nEnter the gate to begin the real mission.\nGood luck, Vector.", "[ ENTER THE EXTRACTION PORTAL ]"); _spawn_tut_entity("portal")

func _set_tut_text(story: String, instr: String) -> void:
	if not _tut_label: return
	_tut_label.text = story; _tut_instruction.text = instr; _tut_label.modulate.a = 0
	create_tween().tween_property(_tut_label, "modulate:a", 1.0, 0.4)

func _spawn_tut_entity(type: String) -> void:
	match type:
		"enemy":
			var e = enemy_scene.instantiate(); e.global_position = player.global_position + Vector2(300, 0); e.enemy_type = "melee"; dynamic_entities.add_child(e); total_enemies_in_level = 1; enemies_killed_in_level = 0
		"core":
			var c = crystal_scene.instantiate(); c.global_position = player.global_position + Vector2(0, -300); dynamic_entities.add_child(c); cores_required = 1; cores_collected = 0
		"portal":
			portal_instance = portal_scene.instantiate(); portal_instance.global_position = player.global_position + Vector2(-300, 0); dynamic_entities.add_child(portal_instance); portal_unlocked = true; portal_instance.activate()

func _start_range_sequence() -> void:
	current_level = 99; is_waiting_to_start = false; _clear_static_nodes()
	var map_w = 1800.0; var map_h = 1200.0; _rebuild_boundaries(map_w, map_h); _rebuild_navigation(map_w, map_h, [])
	_replay_metadata = {"map_w": map_w, "map_h": map_h, "walls": []}
	if player: player.visible = true; player.global_position = Vector2(map_w/2, map_h/2); player.process_mode = Node.PROCESS_MODE_PAUSABLE
	if shop_hint_label: shop_hint_label.visible = true; shop_hint_label.text = "/// SHOOTING RANGE LINK ESTABLISHED"
	time_remaining = 9999.0; game_active = true; _is_dying = false
	for i in range(15): _spawn_range_enemy(map_w, map_h)

func _spawn_range_enemy(w: float = 1800.0, h: float = 1200.0) -> void:
	var types = ["melee", "ranged", "turret", "patrol"]; var e = enemy_scene.instantiate()
	var p = Vector2(randf_range(150, w - 150), randf_range(150, h - 150))
	if player and p.distance_to(player.global_position) < 400:
		p += (p - player.global_position).normalized() * 400
		p.x = clampf(p.x, 150, w - 150); p.y = clampf(p.y, 150, h - 150)
	e.global_position = p; e.enemy_type = types[randi() % types.size()]; dynamic_entities.add_child(e)

func _setup_screen_shader() -> void:
	var canvas = CanvasLayer.new(); canvas.layer = 100; add_child(canvas)
	var rect = ColorRect.new(); rect.name = "BloomRect"
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.anchor_right = 1.0; rect.anchor_bottom = 1.0; rect.offset_right = 0; rect.offset_bottom = 0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new(); mat.shader = load("res://shader/neon_bloom.gdshader"); rect.material = mat; canvas.add_child(rect)

func _setup_overscreen_hud() -> void:
	var ui = $UI
	for child in ui.get_children(): child.queue_free()
	var root = Control.new(); root.name = "HudRoot"; root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(root)

	var tech_cyan = Color(0.2, 0.8, 1.0)
	var tech_bg = Color(0.01, 0.03, 0.05, 0.45) # More transparent

	var base_style = StyleBoxFlat.new()
	base_style.bg_color = tech_bg
	base_style.border_width_left = 2; base_style.border_width_top = 2
	base_style.border_color = tech_cyan * 1.5
	base_style.skew = Vector2(0.05, 0.0)
	base_style.corner_radius_top_left = 1
	base_style.content_margin_left = 15; base_style.content_margin_right = 15
	base_style.content_margin_top = 8; base_style.content_margin_bottom = 8
	base_style.shadow_color = tech_cyan * 0.2; base_style.shadow_size = 6

	var decal_color = tech_cyan * 0.4
	for corner in [Control.PRESET_TOP_LEFT, Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT]:
		var c_box = Control.new(); c_box.set_anchors_and_offsets_preset(corner); root.add_child(c_box)
		var h_line = ColorRect.new(); h_line.color = decal_color; h_line.custom_minimum_size = Vector2(60, 1); c_box.add_child(h_line)
		var v_line = ColorRect.new(); v_line.color = decal_color; v_line.custom_minimum_size = Vector2(1, 60); c_box.add_child(v_line)

	# TOP LEFT: Stability + Weapon Stack
	var tl_container = VBoxContainer.new(); tl_container.position = Vector2(30, 30); tl_container.add_theme_constant_override("separation", 15); root.add_child(tl_container)
	
	var tl_panel = PanelContainer.new(); tl_panel.add_theme_stylebox_override("panel", base_style); tl_container.add_child(tl_panel)
	var tl_vbox = VBoxContainer.new(); tl_vbox.custom_minimum_size = Vector2(300, 0); tl_vbox.add_theme_constant_override("separation", 4); tl_panel.add_child(tl_vbox)
	var time_header = Label.new(); time_header.text = "[ STABILITY ]"; time_header.add_theme_font_size_override("font_size", 14); time_header.modulate = tech_cyan * 2.0; tl_vbox.add_child(time_header)
	time_bar = ProgressBar.new(); time_bar.custom_minimum_size = Vector2(0, 20); time_bar.show_percentage = false; tl_vbox.add_child(time_bar)
	var bar_bg = base_style.duplicate(); bar_bg.bg_color = Color(0,0,0,0.3); bar_bg.border_width_left = 1; bar_bg.border_width_top = 1; bar_bg.border_width_right = 1; bar_bg.border_width_bottom = 1; bar_bg.border_color = tech_cyan * 0.3
	var bar_fg = base_style.duplicate(); bar_fg.bg_color = tech_cyan * 2.0; bar_fg.border_width_left = 0; bar_fg.border_width_top = 0
	time_bar.add_theme_stylebox_override("background", bar_bg); time_bar.add_theme_stylebox_override("fill", bar_fg)
	inventory_label = Label.new(); inventory_label.text = "NODES: NULL"; inventory_label.add_theme_font_size_override("font_size", 16); inventory_label.modulate = tech_cyan * 1.5; tl_vbox.add_child(inventory_label)

	var bl_panel = PanelContainer.new(); bl_panel.add_theme_stylebox_override("panel", base_style); tl_container.add_child(bl_panel)
	var bl_vbox = VBoxContainer.new(); bl_vbox.custom_minimum_size = Vector2(250, 0); bl_panel.add_child(bl_vbox)
	var weapon_header = Label.new(); weapon_header.text = "[ PULSE_CAP ]"; weapon_header.add_theme_font_size_override("font_size", 14); weapon_header.modulate = tech_cyan * 2.0; bl_vbox.add_child(weapon_header)
	cooldown_bar = ProgressBar.new(); cooldown_bar.custom_minimum_size = Vector2(0, 10); cooldown_bar.show_percentage = false; bl_vbox.add_child(cooldown_bar)
	var heat_fg = bar_fg.duplicate(); heat_fg.bg_color = Color(1.0, 0.8, 0.2) * 2.5; cooldown_bar.add_theme_stylebox_override("background", bar_bg); cooldown_bar.add_theme_stylebox_override("fill", heat_fg)

	# TOP RIGHT: Round + Progress
	var tr_panel = PanelContainer.new(); tr_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT); tr_panel.offset_left = -330; tr_panel.offset_top = 30; tr_panel.offset_right = -30; tr_panel.add_theme_stylebox_override("panel", base_style); root.add_child(tr_panel)
	var tr_vbox = VBoxContainer.new(); tr_vbox.alignment = BoxContainer.ALIGNMENT_END; tr_panel.add_child(tr_vbox)
	level_label = Label.new(); level_label.add_theme_font_size_override("font_size", 48); level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; tr_vbox.add_child(level_label)
	enemies_remaining_label = Label.new(); enemies_remaining_label.add_theme_font_size_override("font_size", 18); enemies_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; tr_vbox.add_child(enemies_remaining_label)
	progress_bar = ProgressBar.new(); progress_bar.custom_minimum_size = Vector2(250, 8); progress_bar.show_percentage = false; tr_vbox.add_child(progress_bar)
	var core_fg = bar_fg.duplicate(); core_fg.bg_color = Color(1.0, 0.4, 0.8) * 2.5; progress_bar.add_theme_stylebox_override("background", bar_bg); progress_bar.add_theme_stylebox_override("fill", core_fg)

	# BOTTOM LEFT: MINIMAP
	var mm_panel = PanelContainer.new(); mm_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT); mm_panel.offset_left = 30; mm_panel.offset_bottom = -30; mm_panel.offset_top = -230; mm_panel.offset_right = 230; mm_panel.add_theme_stylebox_override("panel", base_style); root.add_child(mm_panel)
	var mm_cont = SubViewportContainer.new(); mm_cont.stretch = true; mm_panel.add_child(mm_cont)
	minimap_view = SubViewport.new(); minimap_view.handle_input_locally = false; minimap_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; mm_cont.add_child(minimap_view)
	minimap_cam = Camera2D.new(); minimap_view.add_child(minimap_cam)
	# Share the world with the main view
	minimap_view.world_2d = get_viewport().world_2d

	# BOTTOM RIGHT: Credits
	var br_panel = PanelContainer.new(); br_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT); br_panel.offset_left = -220; br_panel.offset_bottom = -30; br_panel.offset_top = -90; br_panel.offset_right = -30; br_panel.add_theme_stylebox_override("panel", base_style); root.add_child(br_panel)
	var br_hbox = HBoxContainer.new(); br_hbox.alignment = BoxContainer.ALIGNMENT_CENTER; br_hbox.add_theme_constant_override("separation", 10); br_panel.add_child(br_hbox)
	var icon_style = StyleBoxFlat.new(); icon_style.bg_color = Color.GOLD * 2.0; icon_style.corner_radius_top_left = 10; icon_style.corner_radius_top_right = 10; icon_style.corner_radius_bottom_left = 10; icon_style.corner_radius_bottom_right = 10
	var coin_icon = Panel.new(); coin_icon.custom_minimum_size = Vector2(20, 20); coin_icon.add_theme_stylebox_override("panel", icon_style); br_hbox.add_child(coin_icon)
	coins_bank_label = Label.new(); coins_bank_label.add_theme_font_size_override("font_size", 32); coins_bank_label.add_theme_color_override("font_color", Color.GOLD * 2.0); br_hbox.add_child(coins_bank_label)

	combo_label = Label.new(); combo_label.add_theme_font_size_override("font_size", 64); combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; combo_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); combo_label.offset_top = -200; root.add_child(combo_label)
	shop_hint_label = Label.new(); shop_hint_label.add_theme_font_size_override("font_size", 32); shop_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; shop_hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER); root.add_child(shop_hint_label)

	var fade_canvas = CanvasLayer.new(); fade_canvas.name = "FadeLayer"; fade_canvas.layer = 99; add_child(fade_canvas)
	fade_overlay = ColorRect.new(); fade_overlay.name = "FadeOverlay"; fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); fade_overlay.color = Color(0, 0, 0, 0); fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; fade_overlay.visible = true; fade_canvas.add_child(fade_overlay)

	var ability_col := VBoxContainer.new(); ability_col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); ability_col.offset_left = -150; ability_col.offset_right = 150; ability_col.offset_top = -45; ability_col.offset_bottom = -5; ability_col.alignment = BoxContainer.ALIGNMENT_END; root.add_child(ability_col)
	ability_bar_label = Label.new(); ability_bar_label.add_theme_font_size_override("font_size", 12); ability_bar_label.add_theme_color_override("font_color", Color.WHITE * 0.8); ability_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; ability_col.add_child(ability_bar_label)
	ability_bar = ProgressBar.new(); ability_bar.custom_minimum_size = Vector2(300, 12); ability_bar.show_percentage = false; ability_bar.max_value = 100.0; ability_bar.value = 0.0
	var fg_ab = StyleBoxFlat.new(); fg_ab.bg_color = Color(0.2, 0.8, 1.0) * 2.0; fg_ab.skew = Vector2(0.1, 0.0)
	var bg_ab = StyleBoxFlat.new(); bg_ab.bg_color = Color(0, 0, 0, 0.7); bg_ab.border_width_left = 1; bg_ab.border_width_top = 1; bg_ab.border_width_right = 1; bg_ab.border_width_bottom = 1; bg_ab.border_color = Color(0.3, 0.3, 0.5); bg_ab.skew = Vector2(0.1, 0.0)
	ability_bar.add_theme_stylebox_override("fill", fg_ab); ability_bar.add_theme_stylebox_override("background", bg_ab); ability_col.add_child(ability_bar)

func _clear_static_nodes() -> void:
	for child in get_children():
		if child.name.begins_with("Enemy") or child.name.begins_with("Crystal") or child.name.begins_with("Coin") or child.name.begins_with("TimeFreezePickup") or child.name == "ExitPortal": child.queue_free()
	var walls = get_node_or_null("Walls")
	if walls:
		for child in walls.get_children():
			if child.name.begins_with("Obstacle"): child.queue_free()
	var wall_visuals = get_node_or_null("WallVisuals")
	if wall_visuals:
		for child in wall_visuals.get_children(): child.queue_free()

func _start_level(level: int, open_shop: bool = true) -> void:
	if _transition_tween: _transition_tween.kill(); _transition_tween = null
	_replay_frames.clear(); _replay_record_timer = 0.0
	current_level = level; cores_collected = 0; coins_collected = 0; enemies_killed_in_level = 0; total_enemies_in_level = 0; portal_unlocked = false; game_active = true; _is_dying = false; is_waiting_to_start = true; _transition_lock_timer = TRANSITION_DELAY; _was_moving_on_load = true
	Engine.time_scale = 1.0
	_is_transitioning = false; target_time_scale = SLOW_TIME_SCALE; _ghost_check_timer = 2.0
	_target_zoom = BASE_ZOOM; _shot_heat_multiplier = 0
	if camera: camera.zoom = Vector2.ONE * BASE_ZOOM
	if minimap_view: minimap_view.world_2d = get_viewport().world_2d
	if player: player.visible = true
	if dynamic_entities: dynamic_entities.visible = true
	if bg: bg.visible = true
	if dynamic_walls: dynamic_walls.visible = true
	var shop = get_node_or_null("ShopUI"); if shop: shop.queue_free()
	var go = get_node_or_null("GameOverUI"); if go: go.queue_free()
	if player:
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		player.move_speed = 130.0 * (1.0 + inventory.count("SPEED") * 0.15)
		player.shoot_cooldown = 0.3 * (1.0 - inventory.count("COOL") * 0.15)
	for child in $UI.get_children():
		if child is Label:
			if child.name.begins_with("BonusLabel") or child.text.contains("!") or child.text.contains("WIPEOUT"):
				child.queue_free()
			elif child == combo_label:
				child.visible = false
	if fade_overlay:
		fade_overlay.color = Color.BLACK
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); tw.tween_property(fade_overlay, "color:a", 0.0, 0.2)
	cores_required = int(1 + floor(level / 3.0)); time_remaining = STARTING_TIME + (level - 1) * 2.0 + (inventory.count("TIME") * 10.0)
	for child in dynamic_entities.get_children(): child.queue_free()
	for child in dynamic_walls.get_children(): child.queue_free()
	
	# Ensure map is large enough for all entities (enemies, walls, crystals, coins)
	# Using 2^level for exponential growth as requested
	var enemy_count = int(pow(2, level))
	var wall_count = 5 + level
	var coin_count = 1 + int(level / 2.0)
	var total_items = enemy_count + wall_count + cores_required + coin_count + 10 
	
	# "Snug and tight" - reduced area per item from 35000 to 15000
	var min_area_required = total_items * 15000.0
	
	var map_w = 700.0 + (level - 1) * 30.0
	var map_h = 500.0 + (level - 1) * 22.5
	var current_area = map_w * map_h
	
	if current_area < min_area_required:
		var expansion_factor = sqrt(min_area_required / current_area)
		map_w *= expansion_factor
		map_h *= expansion_factor
	
	_rebuild_boundaries(map_w, map_h)
	if player: player.global_position = Vector2(map_w / 2.0, map_h / 2.0)
	var inner_rects = _generate_inner_walls(level, map_w, map_h)
	_replay_metadata = {
		"map_w": map_w,
		"map_h": map_h,
		"walls": inner_rects
	}
	_rebuild_navigation(map_w, map_h, inner_rects); _spawn_entities(level, map_w, map_h, inner_rects)
	_last_real_ms = Time.get_ticks_msec(); _update_ui()
	if open_shop: _open_shop()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_settings_open: _close_settings()
		elif not is_shop_open: _open_settings()
		return
	if is_waiting_to_start and event.is_action_pressed("shop") and _transition_lock_timer <= 0.0:
		if not is_shop_open: _open_shop()
		else: _close_shop()

func _process(delta: float) -> void:
	var now = Time.get_ticks_msec(); var real_delta = (now - _last_real_ms) / 1000.0; _last_real_ms = now

	if _game_mode == "tutorial":
		if _tutorial_step == 1 and player and player.velocity.length() > 20: _advance_tutorial()
		elif _tutorial_step == 2 and player and player.velocity.length() > 50:
			_tut_timer -= delta; if _tut_timer <= 0: _advance_tutorial()
		elif _tutorial_step == 3 and player and player._is_dashing: _advance_tutorial()
	elif _game_mode == "range":
		time_remaining = 9999.0; _is_dying = false
		if player: _last_shot_time_ms = 0; _shot_heat_multiplier = 0
		_range_respawn_timer -= real_delta
		if _range_respawn_timer <= 0:
			if get_tree().get_nodes_in_group("enemies").size() < 20:
				for i in range(5): _spawn_range_enemy()
			_range_respawn_timer = 2.0

	if player and camera:
		camera.global_position = player.global_position
		var zoom_weight = 1.0 - exp(-_zoom_speed * real_delta)
		camera.zoom = lerp(camera.zoom, Vector2.ONE * _target_zoom, zoom_weight)
		if shake_duration > 0.0:
			shake_duration -= real_delta; camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
			if shake_duration <= 0.0: camera.offset = Vector2.ZERO

	if is_shop_open: return

	if is_waiting_to_start:
		if _transition_lock_timer > 0.0: _transition_lock_timer -= real_delta; shop_hint_label.text = "SYNCING..."
		else: shop_hint_label.text = "MOVE TO INITIATE"
		Engine.time_scale = SLOW_TIME_SCALE
		return

	# Ability timers
	if _invisible_timer > 0.0:
		_invisible_timer -= real_delta
		if _invisible_timer <= 0.0:
			player_invisible = false
			_show_big_bonus_message("VEIL LIFTED")
	if _bullet_time_active:
		_bullet_time_timer -= real_delta
		if _bullet_time_timer <= 0.0:
			_bullet_time_active = false
			target_time_scale = SLOW_TIME_SCALE
	if _time_warp_active:
		_time_warp_timer -= real_delta
		if _time_warp_timer <= 0.0:
			_time_warp_active = false
			Engine.time_scale = SLOW_TIME_SCALE
			target_time_scale = SLOW_TIME_SCALE
			_show_big_bonus_message("WARP ENDED")
		return

	if not game_active:
		if _is_transitioning: Engine.time_scale = 1.0
		return

	# Ghost enemy safety check
	_ghost_check_timer -= real_delta
	if not _is_transitioning and total_enemies_in_level > 0 and _ghost_check_timer <= 0.0:
		if get_tree().get_nodes_in_group("enemies").size() == 0:
			_show_big_bonus_message("WIPEOUT!"); total_coins_collected += 50; _initiate_level_transition(0.3)
			return

	total_time_elapsed += real_delta; time_remaining -= delta
	if _is_dying:
		_death_grace_timer -= real_delta
		if _death_grace_timer <= 0.0: _handle_death(); return
	elif time_remaining <= 0.0:
		time_remaining = 0.0; _is_dying = true; _death_grace_timer = DEATH_GRACE_TIME

	var ts_weight = 1.0 - exp(-TIME_LERP_SPEED * real_delta)
	var next_ts = lerp(Engine.time_scale, target_time_scale, ts_weight)
	Engine.time_scale = clampf(next_ts, 0.0, 1.0)

	if combo_count > 0:
		combo_timer -= real_delta
		if combo_timer <= 0.0: combo_count = 0; _update_ui()
	_update_ui()
	
	if game_active and not _is_transitioning:
		_replay_record_timer -= real_delta
		if _replay_record_timer <= 0.0:
			_replay_record_timer += REPLAY_RECORD_RATE
			_record_replay_frame()

func set_player_active(active: bool) -> void:
	if is_shop_open: return
	if is_waiting_to_start:
		if active and not _was_moving_on_load and _transition_lock_timer <= 0.0:
			is_waiting_to_start = false; _last_real_ms = Time.get_ticks_msec(); shop_hint_label.visible = false
		elif not active:
			_was_moving_on_load = false
	target_time_scale = NORMAL_TIME_SCALE if active else SLOW_TIME_SCALE

func _handle_death() -> void:
	if inventory.has("LIFE"):
		inventory.erase("LIFE"); _is_dying = false; time_remaining = 30.0; _show_big_bonus_message("LIFE CONSUMED!"); trigger_screen_shake(0.5, 25.0); _pulse_zoom(BASE_ZOOM - 0.2, 15.0)
	else: _trigger_game_over()

func player_shoot(lethal: bool = false) -> void:
	var now = Time.get_ticks_msec()
	if now - _last_shot_time_ms < HEAT_WINDOW_MS: _shot_heat_multiplier += 1
	else: _shot_heat_multiplier = 0
	_last_shot_time_ms = now
	if not lethal:
		var current_cost = BASE_SHOOT_COST + (_shot_heat_multiplier * 5.0); subtract_time(current_cost)
	_pulse_zoom(BASE_ZOOM + 0.05, 40.0)

func player_hit(amount: float = HIT_COST) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("hit")
	subtract_time(amount); trigger_screen_shake(0.3, 15.0); _pulse_zoom(BASE_ZOOM - 0.1, 20.0)

func enemy_killed(count_toward_wipeout: bool = true) -> void:
	if not game_active: return
	total_enemies_killed += 1
	if player and player.has_method("enemy_killed_reward"):
		player.enemy_killed_reward()
	
	if _game_mode == "tutorial" and _tutorial_step == 4: _advance_tutorial()
	elif _game_mode == "range": _update_ui(); return

	if count_toward_wipeout:
		enemies_killed_in_level += 1
	if _is_dying: _is_dying = false; time_remaining = 3.0
	combo_count = mini(combo_count + 1, MAX_COMBO); combo_timer = COMBO_WINDOW; var reward = BASE_KILL_REWARD * combo_count; add_time(reward); _show_combo_popup(combo_count, reward); _pulse_zoom(1.02, 20.0)
	if count_toward_wipeout and enemies_killed_in_level >= total_enemies_in_level:
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("explosion")
		_show_big_bonus_message("WIPEOUT!"); total_coins_collected += 50; _initiate_level_transition(0.3)

func _initiate_level_transition(delay: float) -> void:
	if _is_transitioning: return
	_is_transitioning = true; game_active = false; Engine.time_scale = 1.0; _target_zoom = BASE_ZOOM + 0.3
	_transition_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_transition_tween.tween_interval(delay)
	_transition_tween.tween_callback(func():
		_show_round_complete_menu()
	)

func _show_round_complete_menu() -> void:
	var canvas = CanvasLayer.new(); canvas.name = "RoundCompleteUI"; canvas.layer = 50; add_child(canvas)
	var center = CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); canvas.add_child(center)
	var panel = PanelContainer.new(); panel.custom_minimum_size = Vector2(400, 200); center.add_child(panel)
	
	var tech_cyan = Color(0.2, 0.8, 1.0); var tech_bg = Color(0.01, 0.03, 0.05, 0.95)
	var p_style = StyleBoxFlat.new(); p_style.bg_color = tech_bg; p_style.border_width_left = 4; p_style.border_width_top = 4; p_style.border_color = tech_cyan; p_style.skew = Vector2(0.05, 0.0); p_style.shadow_color = tech_cyan * 0.3; p_style.shadow_size = 20
	p_style.content_margin_left = 30; p_style.content_margin_right = 30; p_style.content_margin_top = 30; p_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", p_style)

	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 20); panel.add_child(vbox)
	var title = Label.new(); title.text = "/// ROUND COMPLETE"; title.add_theme_font_size_override("font_size", 32); title.add_theme_color_override("font_color", tech_cyan * 2.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(title)
	vbox.add_child(HSeparator.new())
	
	var btn_style = StyleBoxFlat.new(); btn_style.bg_color = Color(0.1, 0.2, 0.3, 0.4); btn_style.border_width_left = 2; btn_style.border_color = tech_cyan * 0.5; btn_style.skew = Vector2(0.1, 0.0)
	var btn_hover = btn_style.duplicate(); btn_hover.bg_color = tech_cyan * 0.2; btn_hover.border_color = tech_cyan * 2.0
	
	var btn_replay = Button.new(); btn_replay.text = ">> WATCH TACTICAL REPLAY"; btn_replay.custom_minimum_size = Vector2(0, 60); btn_replay.add_theme_stylebox_override("normal", btn_style); btn_replay.add_theme_stylebox_override("hover", btn_hover)
	btn_replay.pressed.connect(func():
		if has_node("/root/AudioManager"): get_node("/root/AudioManager").play_sfx("click")
		canvas.queue_free()
		_start_replay_mode()
	)
	vbox.add_child(btn_replay)
	
	var btn_next = Button.new(); btn_next.text = ">> INITIATE NEXT SEQUENCE"; btn_next.custom_minimum_size = Vector2(0, 60); btn_next.add_theme_stylebox_override("normal", btn_style); btn_next.add_theme_stylebox_override("hover", btn_hover)
	btn_next.pressed.connect(func():
		if has_node("/root/AudioManager"): get_node("/root/AudioManager").play_sfx("click")
		canvas.queue_free()
		_fade_to_next_level()
	)
	vbox.add_child(btn_next)

func _start_replay_mode() -> void:
	get_tree().paused = true
	if is_instance_valid(player): player.visible = false
	if dynamic_entities: dynamic_entities.visible = false
	if bg: bg.visible = false
	if dynamic_walls: dynamic_walls.visible = false
	for c in get_children():
		if c.is_in_group("player_bullets") or c.is_in_group("enemy_projectiles"):
			c.visible = false
			
	var viewer = preload("res://scripts/replay_viewer.gd").new()
	viewer.name = "ReplayViewer"
	viewer.setup(_replay_frames, _replay_metadata, camera)
	viewer.exit_requested.connect(func():
		viewer.queue_free()
		if is_instance_valid(player): player.visible = true
		if dynamic_entities: dynamic_entities.visible = true
		if bg: bg.visible = true
		if dynamic_walls: dynamic_walls.visible = true
		for c in get_children():
			if c.is_in_group("player_bullets") or c.is_in_group("enemy_projectiles"):
				c.visible = true
		get_tree().paused = false
		_fade_to_next_level()
	)
	add_child(viewer)

func _fade_to_next_level() -> void:
	if is_instance_valid(fade_overlay):
		var ftw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		ftw.tween_property(fade_overlay, "color:a", 1.0, 0.2)
		ftw.finished.connect(func(): _start_level(current_level + 1))
	else:
		_start_level(current_level + 1)

func _record_replay_frame() -> void:
	var ents = []
	var p_pos = Vector2.ZERO
	if is_instance_valid(player):
		p_pos = player.global_position
		var ppoly = player.get_node_or_null("Polygon2D")
		var c = ppoly.color if ppoly else Color.WHITE
		ents.append([0, p_pos.x, p_pos.y, player.global_rotation, player.scale.x, player.scale.y, c.r, c.g, c.b, c.a])
	
	if dynamic_entities:
		for child in dynamic_entities.get_children():
			if child.is_in_group("enemies"):
				var ep = child.get_node_or_null("Polygon2D")
				var c = ep.color if ep else Color.RED
				ents.append([1, child.global_position.x, child.global_position.y, child.global_rotation, child.scale.x, child.scale.y, c.r, c.g, c.b, c.a])
			elif child.name.begins_with("Coin") or child.name.begins_with("Crystal") or child.name.begins_with("TimeFreeze") or child.name.begins_with("TimeWarp"):
				var sc = child.scale
				ents.append([3, child.global_position.x, child.global_position.y, 0.0, sc.x, sc.y, 1.0, 1.0, 0.0, 1.0])
	
	for child in get_children():
		if child.is_in_group("player_bullets") or child.is_in_group("enemy_projectiles"):
			ents.append([2, child.global_position.x, child.global_position.y, child.global_rotation, 1.0, 1.0, 1.0, 1.0, 0.5, 1.0])
			
	_replay_frames.append({
		"time": total_time_elapsed,
		"cam_pos": p_pos, # Record player pos as cam focus
		"ents": ents
	})

func _pulse_zoom(amt: float, speed: float) -> void:
	if not camera: return
	camera.zoom = Vector2.ONE * amt; _zoom_speed = speed

func collect_core() -> void:
	cores_collected += 1
	if cores_collected >= cores_required: _unlock_portal(); _pulse_zoom(BASE_ZOOM + 0.1, 15.0)
	_update_ui()

func collect_coin() -> void:
	coins_collected += 1; total_coins_collected += 1; _update_ui()

func collect_time_freeze(bonus: float) -> void:
	add_time(bonus); _flash_timer_label()

func add_time(amount: float) -> void:
	var limit = STARTING_TIME + (current_level - 1) * 5.0 + (inventory.count("TIME") * 10.0)
	time_remaining = minf(time_remaining + amount, limit); if time_remaining > 0.1: _is_dying = false

func subtract_time(amount: float) -> void:
	time_remaining = maxf(time_remaining - amount, -2.0)
	if time_remaining <= 0.0 and not _is_dying: _is_dying = true; _death_grace_timer = DEATH_GRACE_TIME

func update_ability_bar(charge: float, max_charge: float, ready: bool, colour: Color) -> void:
	if not ability_bar: return
	ability_bar.max_value = max_charge; ability_bar.value = charge
	var fg := StyleBoxFlat.new(); fg.bg_color = (Color.WHITE * 3.0 if ready else colour * 2.5); fg.skew = Vector2(0.2, 0.0)
	ability_bar.add_theme_stylebox_override("fill", fg)
	if ability_bar_label:
		ability_bar_label.text = "[ E ] ABILITY READY" if ready else "ABILITY  %.0f / %.0f" % [charge, max_charge]
		ability_bar_label.add_theme_color_override("font_color", Color.WHITE * (2.0 if ready else 0.8))

func trigger_bullet_time(duration: float) -> void:
	_bullet_time_active = true; _bullet_time_timer = duration; target_time_scale = 0.02
	trigger_screen_shake(0.2, 8.0); _show_big_bonus_message("OVERCLOCK — %.0fs" % duration)

func trigger_invisibility(duration: float) -> void:
	player_invisible = true; _invisible_timer = duration
	trigger_screen_shake(0.2, 6.0); _show_big_bonus_message("SPECTRAL VEIL — %.0fs" % duration)

func trigger_purge_wipeout() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("die"): e.die()
	trigger_screen_shake(0.5, 20.0); _show_big_bonus_message("MASS DELETION")

func activate_time_warp(duration: float) -> void:
	_time_warp_active = true; _time_warp_timer = duration; Engine.time_scale = 1.0; target_time_scale = 1.0
	trigger_screen_shake(0.3, 10.0); _show_big_bonus_message("TIME WARP!")

func trigger_screen_shake(duration: float, strength: float) -> void:
	shake_duration = duration; shake_strength = strength

func _unlock_portal() -> void:
	portal_unlocked = true; if portal_instance: portal_instance.activate()

func _trigger_game_over() -> void:
	game_active = false; Engine.time_scale = 1.0
	var is_new_best := false
	if Engine.has_singleton("Highscore"):
		is_new_best = Engine.get_singleton("Highscore").submit(current_level, total_enemies_killed, total_time_elapsed)
	elif has_node("/root/Highscore"):
		is_new_best = get_node("/root/Highscore").submit(current_level, total_enemies_killed, total_time_elapsed)
	_show_game_over_screen(is_new_best)

func _open_shop() -> void:
	if is_shop_open: return
	is_shop_open = true; get_tree().paused = true
	var canvas = CanvasLayer.new(); canvas.name = "ShopUI"; canvas.layer = 20; add_child(canvas)
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	var center = CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); canvas.add_child(center)
	var tech_cyan = Color(0.2, 0.8, 1.0); var tech_bg = Color(0.01, 0.03, 0.05, 0.95)
	var panel = PanelContainer.new(); panel.custom_minimum_size = Vector2(850, 600); center.add_child(panel)
	panel.pivot_offset = Vector2(425, 300)
	var p_style = StyleBoxFlat.new(); p_style.bg_color = tech_bg; p_style.border_width_left = 4; p_style.border_width_top = 4; p_style.border_color = tech_cyan; p_style.skew = Vector2(0.05, 0.0); p_style.shadow_color = tech_cyan * 0.3; p_style.shadow_size = 20
	p_style.content_margin_left = 40; p_style.content_margin_right = 40; p_style.content_margin_top = 40; p_style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", p_style)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 25); panel.add_child(vbox)
	var title = Label.new(); title.text = "/// UPGRADE_TERMINAL_V4.6"; title.add_theme_font_size_override("font_size", 42); title.add_theme_color_override("font_color", tech_cyan * 2.0); title.add_theme_color_override("font_outline_color", Color.BLACK); title.add_theme_constant_override("outline_size", 8); vbox.add_child(title)
	var max_slots = int(1 + floor(current_level / 10.0))
	var info = Label.new(); info.text = "STORAGE: %d/%d  |  CREDITS: %d" % [inventory.size(), max_slots, total_coins_collected]; info.add_theme_font_size_override("font_size", 22); info.modulate = tech_cyan * 0.8; vbox.add_child(info)
	var sep = HSeparator.new(); sep.custom_minimum_size = Vector2(0, 10); vbox.add_child(sep)
	var grid = GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation", 20); grid.add_theme_constant_override("v_separation", 20); vbox.add_child(grid)
	var items = [["EXTRA LIFE", 500, "LIFE", "RESTORE SYSTEM ON FAILURE"], ["OVERCLOCK", 350, "COOL", "REDUCE WEAPON COOLDOWN"], ["CHRONO-STAB", 250, "TIME", "EXTEND MISSION DURATION"], ["SERVO-TUNE", 300, "SPEED", "INCREASE CHASSIS VELOCITY"]]
	var btn_normal = StyleBoxFlat.new(); btn_normal.bg_color = Color(0.1, 0.2, 0.3, 0.4); btn_normal.border_width_left = 2; btn_normal.border_color = tech_cyan * 0.5; btn_normal.skew = Vector2(0.1, 0.0)
	var btn_hover = btn_normal.duplicate(); btn_hover.bg_color = tech_cyan * 0.2; btn_hover.border_color = tech_cyan * 2.0
	for item in items:
		var item_vbox = VBoxContainer.new(); grid.add_child(item_vbox)
		var b = Button.new(); b.text = "%s [%d]" % [item[0], item[1]]; b.custom_minimum_size = Vector2(380, 70); b.add_theme_stylebox_override("normal", btn_normal); b.add_theme_stylebox_override("hover", btn_hover); b.pressed.connect(func():
			if has_node("/root/AudioManager"): get_node("/root/AudioManager").play_sfx("click")
			_buy_upgrade(item[2], item[1], info, max_slots)
		); item_vbox.add_child(b)
		var desc = Label.new(); desc.text = item[3]; desc.add_theme_font_size_override("font_size", 14); desc.modulate = Color.GRAY; item_vbox.add_child(desc)
	vbox.add_spacer(false)
	var close_btn = Button.new(); close_btn.text = ">> INITIATE_NEXT_SEQUENCE"; close_btn.custom_minimum_size = Vector2(0, 60); close_btn.add_theme_stylebox_override("normal", btn_normal); close_btn.add_theme_stylebox_override("hover", btn_hover); close_btn.pressed.connect(func():
		if has_node("/root/AudioManager"): get_node("/root/AudioManager").play_sfx("click")
		_close_shop()
		is_waiting_to_start = false
	); vbox.add_child(close_btn)
	panel.modulate.a = 0.0; panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.2); tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _buy_upgrade(type: String, cost: int, info_label: Label, max_slots: int) -> void:
	if inventory.size() >= max_slots: _show_big_bonus_message("SLOTS FULL!"); return
	if total_coins_collected >= cost:
		total_coins_collected -= cost; inventory.append(type); _update_ui(); info_label.text = "STORAGE: %d / %d  |  CREDITS: %d" % [inventory.size(), max_slots, total_coins_collected]; _show_big_bonus_message("ACQUIRED: " + type)
	else: _show_big_bonus_message("INSUFFICIENT CREDITS")

func _close_shop() -> void:
	var shop = get_node_or_null("ShopUI"); if shop: shop.queue_free()
	is_shop_open = false; get_tree().paused = false; _last_real_ms = Time.get_ticks_msec()
	_transition_lock_timer = 0.2; is_waiting_to_start = true; _was_moving_on_load = true
	Engine.time_scale = SLOW_TIME_SCALE; target_time_scale = SLOW_TIME_SCALE
	shop_hint_label.visible = true; shop_hint_label.text = "MOVE TO INITIATE"

func _open_settings() -> void:
	if is_settings_open or is_shop_open: return
	is_settings_open = true; get_tree().paused = true
	var canvas = CanvasLayer.new(); canvas.name = "SettingsUI"; canvas.layer = 25; add_child(canvas)
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg_rect = ColorRect.new(); bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg_rect.color = Color(0, 0, 0, 0.6); canvas.add_child(bg_rect)
	var center = CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); canvas.add_child(center)
	var tech_cyan = Color(0.2, 0.8, 1.0); var tech_bg = Color(0.01, 0.03, 0.05, 0.95)
	var panel = PanelContainer.new(); panel.custom_minimum_size = Vector2(700, 550); center.add_child(panel)
	var p_style = StyleBoxFlat.new(); p_style.bg_color = tech_bg; p_style.border_width_left = 4; p_style.border_width_top = 4; p_style.border_color = tech_cyan; p_style.skew = Vector2(0.02, 0.0); p_style.shadow_color = tech_cyan * 0.3; p_style.shadow_size = 20
	p_style.content_margin_left = 30; p_style.content_margin_right = 30; p_style.content_margin_top = 30; p_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", p_style)
	var main_vbox = VBoxContainer.new(); main_vbox.add_theme_constant_override("separation", 15); panel.add_child(main_vbox)
	var title = Label.new(); title.text = "/// SYSTEM_SETTINGS_V4.6"; title.add_theme_font_size_override("font_size", 32); title.add_theme_color_override("font_color", tech_cyan * 2.0); main_vbox.add_child(title)
	var tab_container = TabContainer.new(); tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL; main_vbox.add_child(tab_container)
	var t_style = StyleBoxFlat.new(); t_style.bg_color = Color(0,0,0,0); t_style.border_width_bottom = 2; t_style.border_color = tech_cyan
	tab_container.add_theme_stylebox_override("panel", t_style)
	var basic_vbox = VBoxContainer.new(); basic_vbox.name = "PRIMARY_AUDIO"; basic_vbox.add_theme_constant_override("separation", 20); tab_container.add_child(basic_vbox)
	basic_vbox.add_child(Control.new())
	_add_vol_slider(basic_vbox, "MASTER_LINK", func(v): AudioManager.set_master_volume(v), AudioManager.get_master_volume())
	_add_vol_slider(basic_vbox, "MUSIC_STREAM", func(v): AudioManager.set_music_volume(v), AudioManager.get_music_volume())
	var adv_vbox = ScrollContainer.new(); adv_vbox.name = "SUB_SYSTEMS"; tab_container.add_child(adv_vbox)
	var adv_list = VBoxContainer.new(); adv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; adv_vbox.add_child(adv_list)
	adv_list.add_child(Control.new())
	var sfx_keys = ["shoot", "hit", "pickup", "click", "explosion"]
	for sfx in sfx_keys:
		_add_vol_slider(adv_list, sfx.to_upper() + "_LEVEL", func(v): AudioManager.set_sfx_volume(sfx, v), AudioManager.get_sfx_volume(sfx))
	var btn_style = StyleBoxFlat.new(); btn_style.bg_color = Color(0.1, 0.2, 0.3, 0.4); btn_style.border_width_left = 2; btn_style.border_color = tech_cyan * 0.5; btn_style.skew = Vector2(0.1, 0.0)
	var btn_h = btn_style.duplicate(); btn_h.bg_color = tech_cyan * 0.2; btn_h.border_color = tech_cyan * 2.0
	var footer_hbox = HBoxContainer.new(); footer_hbox.add_theme_constant_override("separation", 20); main_vbox.add_child(footer_hbox)
	var resume_btn = Button.new(); resume_btn.text = ">> RESUME"; resume_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL; resume_btn.custom_minimum_size = Vector2(0, 50); resume_btn.add_theme_stylebox_override("normal", btn_style); resume_btn.add_theme_stylebox_override("hover", btn_h); resume_btn.pressed.connect(func(): _close_settings()); footer_hbox.add_child(resume_btn)
	var quit_btn = Button.new(); quit_btn.text = ">> TERMINATE"; quit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL; quit_btn.custom_minimum_size = Vector2(0, 50); quit_btn.add_theme_stylebox_override("normal", btn_style); quit_btn.add_theme_stylebox_override("hover", btn_h); quit_btn.pressed.connect(func(): get_tree().quit()); footer_hbox.add_child(quit_btn)
	panel.modulate.a = 0.0; panel.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.15); tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _add_vol_slider(parent: Node, label_text: String, callback: Callable, initial_val: float) -> void:
	var hbox = HBoxContainer.new(); parent.add_child(hbox)
	var l = Label.new(); l.text = label_text + ": "; l.custom_minimum_size = Vector2(180, 0); hbox.add_child(l)
	var s = HSlider.new(); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL; s.min_value = 0.0; s.max_value = 1.0; s.step = 0.05; s.value = initial_val; hbox.add_child(s)
	s.value_changed.connect(callback)

func _close_settings() -> void:
	var settings = get_node_or_null("SettingsUI"); if settings: settings.queue_free()
	is_settings_open = false; get_tree().paused = false; _last_real_ms = Time.get_ticks_msec()

func _show_game_over_screen(is_new_best: bool = false) -> void:
	game_active = false
	var go = CanvasLayer.new(); go.name = "GameOverUI"; go.layer = 30; add_child(go)
	var alert_red = Color(1.0, 0.2, 0.2); var tech_bg = Color(0.05, 0.01, 0.01, 0.95)
	var p = ColorRect.new(); p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); p.color = Color(0.1, 0, 0, 0.7); go.add_child(p)
	var center = CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); go.add_child(center)
	var panel = PanelContainer.new(); panel.custom_minimum_size = Vector2(620, 620); panel.pivot_offset = Vector2(310, 310); center.add_child(panel)
	var p_style = StyleBoxFlat.new(); p_style.bg_color = tech_bg; p_style.border_width_left = 4; p_style.border_width_top = 4; p_style.border_color = (Color.GOLD if is_new_best else alert_red); p_style.skew = Vector2(-0.05, 0.0); p_style.shadow_color = (Color.GOLD * 0.3 if is_new_best else alert_red * 0.3); p_style.shadow_size = 25
	p_style.content_margin_left = 40; p_style.content_margin_right = 40; p_style.content_margin_top = 40; p_style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", p_style)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 18); panel.add_child(vbox)
	var t = Label.new(); t.text = "NEW RECORD!!" if is_new_best else "CRITICAL_SYSTEM_FAILURE"
	t.add_theme_font_size_override("font_size", 40); t.add_theme_color_override("font_color", Color.GOLD * 2.5 if is_new_best else alert_red * 2.0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(t)
	vbox.add_child(HSeparator.new())
	var stats = [["ROUND REACHED", current_level], ["ELIMINATIONS", total_enemies_killed], ["CREDITS EARNED", total_coins_collected], ["TIME SURVIVED", "%.1fs" % total_time_elapsed]]
	for stat in stats:
		var hbox = HBoxContainer.new(); vbox.add_child(hbox)
		var l_stat = Label.new(); l_stat.text = stat[0]; l_stat.add_theme_font_size_override("font_size", 22); l_stat.modulate = Color.GRAY; hbox.add_child(l_stat)
		var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hbox.add_child(spacer)
		var r_stat = Label.new(); r_stat.text = str(stat[1]); r_stat.add_theme_font_size_override("font_size", 22); r_stat.add_theme_color_override("font_color", alert_red); hbox.add_child(r_stat)
	var hs_node = get_node_or_null("/root/Highscore")
	if hs_node:
		vbox.add_child(HSeparator.new())
		var hs_title = Label.new(); hs_title.text = "ALL-TIME BESTS"; hs_title.add_theme_font_size_override("font_size", 18); hs_title.add_theme_color_override("font_color", Color.CYAN * 2.0); hs_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(hs_title)
		var hs_stats = [["BEST ROUND", hs_node.best_round], ["BEST KILLS", hs_node.best_kills], ["BEST TIME", "%.1fs" % hs_node.best_time]]
		for stat in hs_stats:
			var hbox = HBoxContainer.new(); vbox.add_child(hbox)
			var l_stat = Label.new(); l_stat.text = stat[0]; l_stat.add_theme_font_size_override("font_size", 18); l_stat.modulate = Color.GRAY; hbox.add_child(l_stat)
			var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hbox.add_child(spacer)
			var r_stat = Label.new(); r_stat.text = str(stat[1]); r_stat.add_theme_font_size_override("font_size", 18); r_stat.add_theme_color_override("font_color", Color.CYAN); hbox.add_child(r_stat)
	vbox.add_spacer(false)
	var btn_style = StyleBoxFlat.new(); btn_style.bg_color = Color(0.2, 0.05, 0.05, 0.5); btn_style.border_width_left = 2; btn_style.border_color = alert_red * 0.5; btn_style.skew = Vector2(-0.1, 0.0)
	var btn_h = btn_style.duplicate(); btn_h.bg_color = alert_red * 0.2; btn_h.border_color = alert_red * 2.0
	var rb = Button.new(); rb.text = "REBOOT_SYSTEM"; rb.custom_minimum_size = Vector2(0, 50); rb.add_theme_stylebox_override("normal", btn_style); rb.add_theme_stylebox_override("hover", btn_h); rb.pressed.connect(func():
		if has_node("/root/AudioManager"): get_node("/root/AudioManager").play_sfx("click")
		get_tree().reload_current_scene()
	); vbox.add_child(rb)
	var mb = Button.new(); mb.text = "TERMINAL_EXIT"; mb.custom_minimum_size = Vector2(0, 50); mb.add_theme_stylebox_override("normal", btn_style); mb.add_theme_stylebox_override("hover", btn_h); mb.pressed.connect(func():
		if has_node("/root/AudioManager"): get_node("/root/AudioManager").play_sfx("click")
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	); vbox.add_child(mb)
	panel.modulate.a = 0.0; panel.scale = Vector2(1.1, 1.1)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.2); tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func portal_entered() -> void:
	if _game_mode == "tutorial":
		if _tutorial_step == 6: get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	if portal_unlocked:
		if enemies_killed_in_level == 0: _show_big_bonus_message("PACIFIST!"); total_coins_collected += 20
		_initiate_level_transition(0.2)

func _show_big_bonus_message(txt: String) -> void:
	var label = Label.new(); label.name = "BonusLabel_" + str(Time.get_ticks_msec()); label.text = txt; label.add_theme_font_size_override("font_size", 48); label.add_theme_color_override("font_color", Color.GOLD * 2.0); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.size = Vector2(1280, 100); label.position = Vector2(0, 300); $UI.add_child(label)
	var tw = label.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1); tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1); tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.8)
	tw.finished.connect(label.queue_free)

func _update_ui() -> void:
	if time_bar:
		var limit = STARTING_TIME + (current_level - 1) * 5.0 + (inventory.count("TIME") * 10.0); time_bar.max_value = limit; time_bar.value = time_remaining; time_bar.modulate = Color.RED * 2.0 if _is_dying else (Color(0.2, 0.9, 1.0) * 2.0 if time_remaining > 20.0 else Color.ORANGE * 2.0)
		if _game_mode == "range": time_bar.value = time_bar.max_value; time_bar.modulate = Color.CYAN * 2.5
	if cooldown_bar and player:
		cooldown_bar.max_value = player.shoot_cooldown; cooldown_bar.value = player.shoot_cooldown - player._shoot_timer
		if _shot_heat_multiplier > 1: cooldown_bar.modulate = Color.RED * 2.5
		elif _shot_heat_multiplier > 0: cooldown_bar.modulate = Color.ORANGE * 2.5
		else: cooldown_bar.modulate = Color.WHITE
	if progress_bar: progress_bar.max_value = cores_required; progress_bar.value = cores_collected
	if level_label: 
		level_label.text = "ROUND %02d" % current_level
		if _game_mode == "range": level_label.text = "TRAINING"
	if enemies_remaining_label:
		enemies_remaining_label.text = "THREATS: %d / %d" % [total_enemies_in_level - enemies_killed_in_level, total_enemies_in_level]
		if _game_mode == "range": enemies_remaining_label.text = "PURGED: %d" % total_enemies_killed
	if coins_bank_label: coins_bank_label.text = "%04d" % total_coins_collected
	if inventory_label: inventory_label.text = "STORAGE: %d / %d" % [inventory.size(), int(1 + floor(current_level / 10.0))]
	if shop_hint_label: shop_hint_label.visible = is_waiting_to_start and not is_shop_open
	if combo_label: combo_label.visible = combo_count > 1; combo_label.text = "COMBO ×%d" % combo_count

func _rebuild_boundaries(w: float, h: float) -> void:
	if camera: camera.limit_left = -100; camera.limit_top = -100; camera.limit_right = int(w + 100); camera.limit_bottom = int(h + 100)
	if minimap_cam:
		minimap_cam.global_position = Vector2(w / 2.0, h / 2.0)
		var zoom_w = 200.0 / (w + 100.0); var zoom_h = 200.0 / (h + 100.0)
		minimap_cam.zoom = Vector2.ONE * minf(zoom_w, zoom_h)
	if bg: bg.size = Vector2(w, h); bg.color = Color(0, 0, 0)
	var walls = get_node_or_null("Walls")
	if walls:
		walls.get_node("TopWall").position = Vector2(w/2, 10); walls.get_node("TopWall").shape.size = Vector2(w, 20); walls.get_node("BottomWall").position = Vector2(w/2, h - 10); walls.get_node("BottomWall").shape.size = Vector2(w, 20); walls.get_node("LeftWall").position = Vector2(10, h/2); walls.get_node("LeftWall").shape.size = Vector2(20, h); walls.get_node("RightWall").position = Vector2(w - 10, h/2); walls.get_node("RightWall").shape.size = Vector2(20, h)
	var wall_visuals = get_node_or_null("WallVisuals")
	if wall_visuals:
		for child in wall_visuals.get_children(): child.queue_free()
		_add_rim_lit_rect(wall_visuals, Vector2(0, 0), Vector2(w, 20))
		_add_rim_lit_rect(wall_visuals, Vector2(0, h - 20), Vector2(w, 20))
		_add_rim_lit_rect(wall_visuals, Vector2(0, 0), Vector2(20, h))
		_add_rim_lit_rect(wall_visuals, Vector2(w - 20, 0), Vector2(20, h))

func _add_rim_lit_rect(parent: Node, pos: Vector2, size: Vector2) -> void:
	var r = ColorRect.new(); r.position = pos; r.size = size; r.color = Color(0, 0, 0); parent.add_child(r)
	var line = ReferenceRect.new(); line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); line.editor_only = false; line.border_color = Color(0.2, 0.8, 1.0) * 2.0; line.border_width = 2.0; r.add_child(line)

func _generate_inner_walls(level: int, w: float, h: float) -> Array:
	var rects = []; 
	# Smaller but more frequent walls
	var num_walls = randi_range(8 + level * 2, 12 + level * 4); 
	var sz = minf(w, h) * 0.2; 
	var safe_zone = Rect2(w/2.0 - sz, h/2.0 - sz, sz * 2.0, sz * 2.0); 
	var static_body = StaticBody2D.new(); static_body.collision_layer = 6; dynamic_walls.add_child(static_body)
	for i in range(num_walls):
		var wall_w = randf_range(20, 80); var wall_h = randf_range(20, 80)
		if randf() > 0.5: wall_w = randf_range(15, 30)
		else: wall_h = randf_range(15, 30)
		var x = randf_range(50, w - 50 - wall_w); var y = randf_range(50, h - 50 - wall_h); var rect = Rect2(x, y, wall_w, wall_h)
		if safe_zone.intersects(rect): continue
		var overlap = false; for r in rects: if r.grow(20.0).intersects(rect): overlap = true; break
		if overlap: continue
		rects.append(rect); var col = CollisionShape2D.new(); var shape = RectangleShape2D.new(); shape.size = rect.size; col.shape = shape; col.position = rect.get_center(); static_body.add_child(col)
		_add_rim_lit_rect(dynamic_walls, rect.position, rect.size)
	return rects

func _rebuild_navigation(w: float, h: float, inner_rects: Array) -> void:
	if not nav_region: return
	var poly = NavigationPolygon.new()
	var outline = PackedVector2Array([Vector2(10, 10), Vector2(w - 10, 10), Vector2(w - 10, h - 10), Vector2(10, h - 10)])
	poly.add_outline(outline)
	for rect in inner_rects:
		var r = rect.grow(15.0)
		var hole = PackedVector2Array([Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y), Vector2(r.position.x, r.end.y)])
		poly.add_outline(hole)
	var source_geometry = NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(poly, source_geometry, nav_region)
	NavigationServer2D.bake_from_source_geometry_data(poly, source_geometry)
	nav_region.navigation_polygon = poly
	NavigationServer2D.region_set_navigation_polygon(nav_region.get_region_rid(), poly)

func _get_random_pos(w: float, h: float, inner_rects: Array, safe_zone: Rect2) -> Vector2:
	for i in range(500): # Increased retries for snug map
		var p = Vector2(randf_range(80, w - 80), randf_range(80, h - 80)); if safe_zone.has_point(p): continue
		var valid = true; for r in inner_rects: if r.grow(40.0).has_point(p): valid = false; break # Tightened grow from 50 to 40
		if valid: return p
	for i in range(100):
		var p = Vector2(randf_range(50, w - 50), randf_range(50, h - 50))
		var valid = true; for r in inner_rects: if r.grow(20.0).has_point(p): valid = false; break # Tightened grow from 30 to 20
		if valid: return p
	return Vector2(w/2.0, h/2.0) + Vector2(randf_range(-50, 50), randf_range(-50, 50))

func _spawn_entities(level: int, w: float, h: float, inner_rects: Array) -> void:
	var sz = minf(w, h) * 0.25; var safe_zone = Rect2(w/2.0 - sz, h/2.0 - sz, sz * 2.0, sz * 2.0)
	portal_instance = portal_scene.instantiate(); portal_instance.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(portal_instance)
	for i in range(cores_required):
		var crystal = crystal_scene.instantiate(); crystal.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(crystal)
	total_coins = 1 + int(floor(level / 2.0))
	for i in range(total_coins):
		var coin = coin_scene.instantiate(); coin.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(coin)
	var num_freezes = 1 if level < 10 else 2
	for i in range(num_freezes):
		var tf = time_freeze_scene.instantiate(); tf.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(tf)
	if level % 5 == 0 and boss_scene:
		_boss_this_level = true
		var boss := boss_scene.instantiate(); boss.global_position = _get_random_pos(w, h, inner_rects, safe_zone)
		boss.max_hp = 2 + int(level / 5); boss.hp = boss.max_hp
		dynamic_entities.add_child(boss); total_enemies_in_level += 1
		_show_big_bonus_message("ARCHITECT DETECTED")
	else:
		_boss_this_level = false
	if level >= 3 and time_warp_scene:
		var tw_pickup := time_warp_scene.instantiate(); tw_pickup.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(tw_pickup)
	var num_enemies = int(pow(2, level)); var types = ["melee", "ranged", "turret", "patrol"]
	for i in range(num_enemies):
		var e = enemy_scene.instantiate(); e.global_position = _get_random_pos(w, h, inner_rects, safe_zone)
		if level <= 2: e.enemy_type = "melee"
		elif level <= 4: e.enemy_type = "melee" if randf() > 0.4 else "patrol"
		elif level <= 7: e.enemy_type = types[randi() % 2] if randf() > 0.3 else "ranged"
		else: e.enemy_type = types[randi() % types.size()]
		if e.enemy_type == "melee": e.move_speed = randf_range(70.0, 85.0 + level * 2.0) * _enemy_speed_mult; e.aggro_range = 400.0 + level * 5.0
		elif e.enemy_type == "ranged": e.shoot_cooldown = maxf(1.0, 2.5 - level * 0.05); e.move_speed = randf_range(50.0, 70.0 + level * 1.5) * _enemy_speed_mult; e.aggro_range = 500.0 + level * 5.0
		elif e.enemy_type == "turret": e.shoot_cooldown = maxf(1.2, 3.0 - level * 0.1); e.aggro_range = 600.0 + level * 10.0
		elif e.enemy_type == "patrol": e.move_speed = randf_range(80.0, 100.0 + level * 2.0) * _enemy_speed_mult
		dynamic_entities.add_child(e)
	total_enemies_in_level += num_enemies

func _show_combo_popup(multiplier: int, reward: float) -> void:
	if not combo_label: return
	combo_label.text = "+%.0fs  ×%d" % [reward, multiplier]; combo_label.visible = true
	var tw = create_tween(); tw.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.08); tw.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.12)

func _flash_timer_label() -> void:
	if not time_bar: return
	var tw = create_tween(); tw.tween_property(time_bar, "modulate", Color.CYAN * 2.0, 0.15); tw.tween_property(time_bar, "modulate", Color.WHITE * 2.0, 0.25)