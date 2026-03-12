extends Node2D

const SLOW_TIME_SCALE  : float = 0.05
const NORMAL_TIME_SCALE: float = 1.0
const TIME_LERP_SPEED  : float = 15.0 # Adjusted for stable formula
const STARTING_TIME    : float = 60.0
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

# Shot Heat System
var _shot_heat_multiplier : int = 0
var _last_shot_time_ms : int = 0
const HEAT_WINDOW_MS : int = 1000

# New Systems
var inventory : Array = []
var is_waiting_to_start : bool = true
var is_shop_open : bool = false
var _transition_lock_timer : float = 0.0
const TRANSITION_DELAY : float = 0.8
var _was_moving_on_load : bool = true

# Camera Effects
const BASE_ZOOM : float = 1.5 
var _target_zoom : float = BASE_ZOOM
var _zoom_speed : float = 10.0 # Adjusted for stable formula

@onready var camera        : Camera2D = get_node_or_null("Camera2D")
@onready var player        : CharacterBody2D = get_node_or_null("Player")
@onready var bg            : ColorRect = get_node_or_null("Background")
@onready var nav_region    : NavigationRegion2D = get_node_or_null("NavigationRegion2D")

# HUD References
var time_bar : ProgressBar
var cooldown_bar : ProgressBar
var progress_bar : ProgressBar
var coins_bank_label : Label
var level_label : Label
var combo_label : Label
var shop_hint_label : Label
var enemies_remaining_label : Label
var inventory_label : Label
var fade_overlay : ColorRect

var portal_scene = preload("res://scenes/exit_portal.tscn")
var enemy_scene = preload("res://scenes/enemy.tscn")
var crystal_scene = preload("res://scenes/time_crystal.tscn")
var coin_scene = preload("res://scenes/bonus_item.tscn")
var time_freeze_scene = preload("res://scenes/time_freeze_pickup.tscn")

var portal_instance: Node2D = null
var dynamic_entities: Node2D = null
var dynamic_walls: Node2D = null

func _ready() -> void:
	add_to_group("game")
	dynamic_entities = Node2D.new(); add_child(dynamic_entities)
	dynamic_walls = Node2D.new(); add_child(dynamic_walls)
	_setup_screen_shader()
	_setup_overscreen_hud()
	_clear_static_nodes()
	_start_level(1, false)

func _setup_screen_shader() -> void:
	var canvas = CanvasLayer.new(); canvas.layer = 100; add_child(canvas)
	var rect = ColorRect.new(); rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new(); mat.shader = load("res://shader/neon_bloom.gdshader"); rect.material = mat; canvas.add_child(rect)

func _setup_overscreen_hud() -> void:
	var ui = $UI
	for child in ui.get_children(): child.queue_free()
	var root = Control.new(); root.name = "HudRoot"; root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); ui.add_child(root)
	var frame_color = Color(0.2, 0.8, 1.0, 0.6)
	for corner in [Control.PRESET_TOP_LEFT, Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT]:
		var c_box = Control.new(); c_box.set_anchors_and_offsets_preset(corner); root.add_child(c_box)
		var h_line = ColorRect.new(); h_line.color = frame_color; h_line.custom_minimum_size = Vector2(120, 4); c_box.add_child(h_line)
		var v_line = ColorRect.new(); v_line.color = frame_color; v_line.custom_minimum_size = Vector2(4, 120); c_box.add_child(v_line)
		if corner == Control.PRESET_TOP_RIGHT: h_line.position = Vector2(-120, 0)
		elif corner == Control.PRESET_BOTTOM_LEFT: v_line.position = Vector2(0, -120)
		elif corner == Control.PRESET_BOTTOM_RIGHT: h_line.position = Vector2(-120, 0); v_line.position = Vector2(0, -120)
	var bg_style = StyleBoxFlat.new(); bg_style.bg_color = Color(0, 0, 0, 0.9); bg_style.border_width_left = 2; bg_style.border_width_top = 2; bg_style.border_width_right = 2; bg_style.border_width_bottom = 2; bg_style.border_color = Color(0.3, 0.3, 0.5); bg_style.skew = Vector2(0.2, 0.0)
	var fg_time = StyleBoxFlat.new(); fg_time.bg_color = Color(0.2, 1.0, 0.8) * 2.0; fg_time.skew = Vector2(0.2, 0.0)
	var tl = VBoxContainer.new(); tl.position = Vector2(50, 50); tl.custom_minimum_size = Vector2(450, 0); root.add_child(tl)
	time_bar = ProgressBar.new(); time_bar.custom_minimum_size = Vector2(450, 24); time_bar.show_percentage = false; time_bar.add_theme_stylebox_override("background", bg_style); time_bar.add_theme_stylebox_override("fill", fg_time); tl.add_child(time_bar)
	inventory_label = Label.new(); inventory_label.add_theme_font_size_override("font_size", 20); inventory_label.add_theme_color_override("font_color", Color.WHITE * 2.0); tl.add_child(inventory_label)
	var tr_box = VBoxContainer.new(); tr_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT); tr_box.offset_left = -450; tr_box.offset_top = 50; tr_box.offset_right = -50; tr_box.alignment = BoxContainer.ALIGNMENT_END; root.add_child(tr_box)
	level_label = Label.new(); level_label.add_theme_font_size_override("font_size", 64); level_label.add_theme_color_override("font_color", Color.WHITE * 2.0); tr_box.add_child(level_label)
	enemies_remaining_label = Label.new(); enemies_remaining_label.add_theme_font_size_override("font_size", 24); enemies_remaining_label.add_theme_color_override("font_color", Color.RED * 3.0); tr_box.add_child(enemies_remaining_label)
	progress_bar = ProgressBar.new(); progress_bar.custom_minimum_size = Vector2(300, 16); progress_bar.show_percentage = false; progress_bar.add_theme_stylebox_override("background", bg_style); var fg_core = fg_time.duplicate(); fg_core.bg_color = Color(1.0, 0.4, 0.8) * 3.0; progress_bar.add_theme_stylebox_override("fill", fg_core); tr_box.add_child(progress_bar)
	var bl = VBoxContainer.new(); bl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT); bl.offset_left = 50; bl.offset_bottom = -50; bl.offset_top = -120; root.add_child(bl)
	cooldown_bar = ProgressBar.new(); cooldown_bar.custom_minimum_size = Vector2(350, 16); cooldown_bar.show_percentage = false; cooldown_bar.add_theme_stylebox_override("background", bg_style); var fg_ammo = fg_time.duplicate(); fg_ammo.bg_color = Color(1.0, 0.8, 0.2) * 3.0; cooldown_bar.add_theme_stylebox_override("fill", fg_ammo); bl.add_child(cooldown_bar)
	var br = VBoxContainer.new(); br.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT); br.offset_left = -450; br.offset_bottom = -50; br.offset_top = -150; br.offset_right = -50; br.alignment = BoxContainer.ALIGNMENT_END; root.add_child(br)
	coins_bank_label = Label.new(); coins_bank_label.add_theme_font_size_override("font_size", 72); coins_bank_label.add_theme_color_override("font_color", Color.GOLD * 3.0); br.add_child(coins_bank_label)
	combo_label = Label.new(); combo_label.add_theme_font_size_override("font_size", 80); combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; combo_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); combo_label.offset_top = -180; root.add_child(combo_label)
	shop_hint_label = Label.new(); shop_hint_label.add_theme_font_size_override("font_size", 48); shop_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; shop_hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER); root.add_child(shop_hint_label)
	fade_overlay = ColorRect.new(); fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); fade_overlay.color = Color(0, 0, 0, 0); ui.add_child(fade_overlay)

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

	current_level = level; cores_collected = 0; coins_collected = 0; enemies_killed_in_level = 0; portal_unlocked = false; game_active = true; _is_dying = false; is_waiting_to_start = true; _transition_lock_timer = TRANSITION_DELAY; _was_moving_on_load = true; Engine.time_scale = 0.0 
	_is_transitioning = false; target_time_scale = SLOW_TIME_SCALE; _ghost_check_timer = 2.0
	_target_zoom = BASE_ZOOM; _shot_heat_multiplier = 0
	if camera: camera.zoom = Vector2.ONE * BASE_ZOOM
	
	# Explicitly clear UI layers
	var shop = get_node_or_null("ShopUI"); if shop: shop.queue_free()
	var go = get_node_or_null("GameOverUI"); if go: go.queue_free()
	
	for child in $UI.get_children():
		if child is Label:
			if child.name.begins_with("BonusLabel") or child.text.contains("!") or child.text.contains("WIPEOUT"): 
				child.queue_free()
			elif child == combo_label:
				child.visible = false
	if fade_overlay:
		fade_overlay.color = Color.BLACK
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS); tw.tween_property(fade_overlay, "color:a", 0.0, 0.2)
	if player:
		player.move_speed = 130.0 * (1.0 + inventory.count("SPEED") * 0.15)
		player.shoot_cooldown = 0.3 * (1.0 - inventory.count("COOL") * 0.15)
	cores_required = int(1 + floor(level / 3.0)); time_remaining = STARTING_TIME + (level - 1) * 5.0 + (inventory.count("TIME") * 10.0)
	for child in dynamic_entities.get_children(): child.queue_free()
	for child in dynamic_walls.get_children(): child.queue_free()
	var map_w = 700.0 + (level - 1) * 60.0; var map_h = 500.0 + (level - 1) * 40.0
	_rebuild_boundaries(map_w, map_h)
	if player: player.global_position = Vector2(map_w / 2.0, map_h / 2.0)
	var inner_rects = _generate_inner_walls(level, map_w, map_h)
	_rebuild_navigation(map_w, map_h, inner_rects); _spawn_entities(level, map_w, map_h, inner_rects)
	_last_real_ms = Time.get_ticks_msec(); _update_ui()
	if open_shop: _open_shop()

func _input(event: InputEvent) -> void:
	if is_waiting_to_start and event.is_action_pressed("shop") and _transition_lock_timer <= 0.0:
		if not is_shop_open: _open_shop()
		else: _close_shop()

func _process(delta: float) -> void:
	var now = Time.get_ticks_msec(); var real_delta = (now - _last_real_ms) / 1000.0; _last_real_ms = now
	
	if player and camera:
		camera.global_position = player.global_position
		# Stable frame-independent lerp
		var zoom_weight = 1.0 - exp(-_zoom_speed * real_delta)
		camera.zoom = lerp(camera.zoom, Vector2.ONE * _target_zoom, zoom_weight)
		if shake_duration > 0.0:
			shake_duration -= real_delta; camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
			if shake_duration <= 0.0: camera.offset = Vector2.ZERO

	if is_shop_open: return
	if is_waiting_to_start:
		if _transition_lock_timer > 0.0: _transition_lock_timer -= real_delta; shop_hint_label.text = "SYNCING..."
		else: shop_hint_label.text = "MOVE TO INITIATE"
		Engine.time_scale = 0.0
		return

	if not game_active:
		if _is_transitioning: Engine.time_scale = 1.0
		return

	# Ghost enemy safety check - Only after level has started and settled
	_ghost_check_timer -= real_delta
	if not _is_transitioning and total_enemies_in_level > 0 and _ghost_check_timer <= 0.0:
		# Add a small delay/buffer before checking group size to ensure nodes are in tree
		if get_tree().get_nodes_in_group("enemies").size() == 0:
			_show_big_bonus_message("WIPEOUT!"); total_coins_collected += 50; _initiate_level_transition(0.3)
			return

	total_time_elapsed += real_delta; time_remaining -= delta 
	if _is_dying:
		_death_grace_timer -= real_delta
		if _death_grace_timer <= 0.0: _handle_death(); return
	elif time_remaining <= 0.0:
		time_remaining = 0.0; _is_dying = true; _death_grace_timer = DEATH_GRACE_TIME
	
	# Stable frame-independent time scale lerp
	var ts_weight = 1.0 - exp(-TIME_LERP_SPEED * real_delta)
	var next_ts = lerp(Engine.time_scale, target_time_scale, ts_weight)
	Engine.time_scale = clampf(next_ts, 0.0, 1.0)
	
	if combo_count > 0:
		combo_timer -= real_delta
		if combo_timer <= 0.0: combo_count = 0; _update_ui()
	_update_ui()

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
	subtract_time(amount); trigger_screen_shake(0.3, 15.0); _pulse_zoom(BASE_ZOOM - 0.1, 20.0)

func enemy_killed() -> void:
	if not game_active: return
	total_enemies_killed += 1; enemies_killed_in_level += 1
	if _is_dying: _is_dying = false; time_remaining = 3.0
	combo_count = mini(combo_count + 1, MAX_COMBO); combo_timer = COMBO_WINDOW; var reward = BASE_KILL_REWARD * combo_count; add_time(reward); _show_combo_popup(combo_count, reward); _pulse_zoom(1.02, 20.0)
	if enemies_killed_in_level >= total_enemies_in_level:
		_show_big_bonus_message("WIPEOUT!"); total_coins_collected += 50; _initiate_level_transition(0.3)

func _initiate_level_transition(delay: float) -> void:
	if _is_transitioning: return
	_is_transitioning = true; game_active = false; Engine.time_scale = 1.0; _target_zoom = BASE_ZOOM + 0.3
	
	_transition_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_transition_tween.tween_interval(delay)
	_transition_tween.tween_callback(func():
		if is_instance_valid(fade_overlay):
			var ftw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			ftw.tween_property(fade_overlay, "color:a", 1.0, 0.2)
			ftw.finished.connect(func(): _start_level(current_level + 1))
		else:
			_start_level(current_level + 1)
	)

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

func trigger_screen_shake(duration: float, strength: float) -> void:
	shake_duration = duration; shake_strength = strength

func _unlock_portal() -> void:
	portal_unlocked = true; if portal_instance: portal_instance.activate()

func _trigger_game_over() -> void:
	game_active = false; Engine.time_scale = 1.0; _show_game_over_screen()

func _open_shop() -> void:
	is_shop_open = true; var canvas = CanvasLayer.new(); canvas.name = "ShopUI"; canvas.layer = 20; add_child(canvas)
	var br_rect = ColorRect.new(); br_rect.size = Vector2(1280, 720); br_rect.color = Color(0, 0, 0, 0.95); canvas.add_child(br_rect)
	var vbox = VBoxContainer.new(); vbox.alignment = BoxContainer.ALIGNMENT_CENTER; vbox.size = Vector2(800, 600); vbox.position = Vector2(640 - 400, 360 - 300); vbox.add_theme_constant_override("separation", 20); canvas.add_child(vbox)
	var title = Label.new(); title.text = "UPGRADE TERMINAL // ROUND " + str(current_level); title.add_theme_font_size_override("font_size", 48); title.add_theme_color_override("font_color", Color.CYAN * 2.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(title)
	var max_slots = int(1 + floor(current_level / 10.0)); var info = Label.new(); info.text = "SLOTS USED: %d / %d  |  CREDITS: %d" % [inventory.size(), max_slots, total_coins_collected]; info.add_theme_font_size_override("font_size", 24); info.add_theme_color_override("font_color", Color.GOLD * 2.0); info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(info)
	var items = [["EXTRA LIFE", 500, "LIFE"], ["COOLING OVERCLOCK", 350, "COOL"], ["CHRONO-STABILITY", 250, "TIME"], ["SERVO TUNING", 300, "SPEED"]]
	for item in items:
		var b = Button.new(); b.text = "%s: %d Credits" % [item[0], item[1]]; b.custom_minimum_size = Vector2(450, 60); b.pressed.connect(func(): _buy_upgrade(item[2], item[1], info, max_slots)); vbox.add_child(b)
	var close_btn = Button.new(); close_btn.text = "INITIATE NEXT ROUND"; close_btn.pressed.connect(func(): _close_shop()); vbox.add_child(close_btn)

func _buy_upgrade(type: String, cost: int, info_label: Label, max_slots: int) -> void:
	if inventory.size() >= max_slots: _show_big_bonus_message("SLOTS FULL!"); return
	if total_coins_collected >= cost:
		total_coins_collected -= cost; inventory.append(type); _update_ui(); info_label.text = "SLOTS USED: %d / %d  |  CREDITS: %d" % [inventory.size(), max_slots, total_coins_collected]; _show_big_bonus_message("ACQUIRED: " + type)
	else: _show_big_bonus_message("INSUFFICIENT CREDITS")

func _close_shop() -> void:
	var shop = get_node_or_null("ShopUI"); if shop: shop.queue_free(); is_shop_open = false; _transition_lock_timer = TRANSITION_DELAY
	# Immediately start the game if they pressed the button
	is_waiting_to_start = false; shop_hint_label.visible = false; _last_real_ms = Time.get_ticks_msec()

func _show_game_over_screen() -> void:
	game_active = false; var go = CanvasLayer.new(); go.name = "GameOverUI"; go.layer = 30; add_child(go)
	var p = ColorRect.new(); p.size = Vector2(1280, 720); p.color = Color(0, 0, 0, 0.9); go.add_child(p)
	var vbox = VBoxContainer.new(); vbox.alignment = BoxContainer.ALIGNMENT_CENTER; vbox.size = Vector2(400, 500); vbox.position = Vector2(640 - 200, 360 - 250); go.add_child(vbox)
	var t = Label.new(); t.text = "SYSTEM FAILURE"; t.add_theme_font_size_override("font_size", 48); t.add_theme_color_override("font_color", Color.RED * 2.0); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(t); vbox.add_child(HSeparator.new())
	var s = [["ROUND REACHED", current_level], ["ELIMINATIONS", total_enemies_killed], ["CREDITS EARNED", total_coins_collected], ["TIME SURVIVED", "%.1fs" % total_time_elapsed]]
	for stat in s:
		var l = Label.new(); l.text = "%s: %s" % [stat[0], str(stat[1])]; l.add_theme_font_size_override("font_size", 24); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; vbox.add_child(l)
	var rb = Button.new(); rb.text = "RESTART SYSTEM"; rb.custom_minimum_size = Vector2(200, 50); rb.pressed.connect(func(): get_tree().reload_current_scene()); vbox.add_child(rb)
	var mb = Button.new(); mb.text = "EXIT TO MAIN MENU"; mb.custom_minimum_size = Vector2(200, 50); mb.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn")); vbox.add_child(mb)

func portal_entered() -> void:
	if portal_unlocked:
		if enemies_killed_in_level == 0: _show_big_bonus_message("PACIFIST!"); total_coins_collected += 20
		_initiate_level_transition(0.2)

func _show_big_bonus_message(txt: String) -> void:
	var label = Label.new(); label.name = "BonusLabel_" + str(Time.get_ticks_msec()); label.text = txt; label.add_theme_font_size_override("font_size", 48); label.add_theme_color_override("font_color", Color.GOLD * 2.0); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.size = Vector2(1280, 100); label.position = Vector2(0, 300); $UI.add_child(label)
	# Bind tween to label node so it's killed if the label is freed
	var tw = label.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1); tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1); tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.8)
	tw.finished.connect(label.queue_free)

func _update_ui() -> void:
	if time_bar:
		var limit = STARTING_TIME + (current_level - 1) * 5.0 + (inventory.count("TIME") * 10.0); time_bar.max_value = limit; time_bar.value = time_remaining; time_bar.modulate = Color.RED * 2.0 if _is_dying else (Color(0.2, 0.9, 1.0) * 2.0 if time_remaining > 20.0 else Color.ORANGE * 2.0)
	if cooldown_bar and player: 
		cooldown_bar.max_value = player.shoot_cooldown; cooldown_bar.value = player.shoot_cooldown - player._shoot_timer
		if _shot_heat_multiplier > 1: cooldown_bar.modulate = Color.RED * 2.5
		elif _shot_heat_multiplier > 0: cooldown_bar.modulate = Color.ORANGE * 2.5
		else: cooldown_bar.modulate = Color.WHITE
	if progress_bar: progress_bar.max_value = cores_required; progress_bar.value = cores_collected
	if level_label: level_label.text = "ROUND %02d" % current_level
	if enemies_remaining_label: enemies_remaining_label.text = "THREATS: %d / %d" % [total_enemies_in_level - enemies_killed_in_level, total_enemies_in_level]
	if coins_bank_label: coins_bank_label.text = "%04d" % total_coins_collected
	if inventory_label: inventory_label.text = "SLOTS: %d / %d" % [inventory.size(), int(1 + floor(current_level / 10.0))]
	if shop_hint_label: shop_hint_label.visible = is_waiting_to_start and not is_shop_open
	if combo_label: combo_label.visible = combo_count > 1; combo_label.text = "COMBO ×%d" % combo_count

func _rebuild_boundaries(w: float, h: float) -> void:
	if camera: camera.limit_left = -100; camera.limit_top = -100; camera.limit_right = int(w + 100); camera.limit_bottom = int(h + 100)
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
	var rects = []; var num_walls = randi_range(3 + level, 5 + level * 2); var sz = minf(w, h) * 0.25; var safe_zone = Rect2(w/2.0 - sz, h/2.0 - sz, sz * 2.0, sz * 2.0); var static_body = StaticBody2D.new(); static_body.collision_layer = 6; dynamic_walls.add_child(static_body)
	for i in range(num_walls):
		var wall_w = randf_range(50, 300)
		var wall_h = randf_range(50, 300)
		if randf() > 0.5:
			wall_w = randf_range(20, 50)
		else:
			wall_h = randf_range(20, 50)
		var x = randf_range(50, w - 50 - wall_w); var y = randf_range(50, h - 50 - wall_h); var rect = Rect2(x, y, wall_w, wall_h)
		if safe_zone.intersects(rect): continue
		var overlap = false; for r in rects: if r.grow(30.0).intersects(rect): overlap = true; break
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
	
	nav_region.navigation_polygon = poly
	# NavigationServer2D sync for immediate use
	NavigationServer2D.region_set_navigation_polygon(nav_region.get_region_rid(), poly)

func _get_random_pos(w: float, h: float, inner_rects: Array, safe_zone: Rect2) -> Vector2:
	for i in range(250): # Increased attempts
		var p = Vector2(randf_range(80, w - 80), randf_range(80, h - 80)); if safe_zone.has_point(p): continue
		var valid = true; for r in inner_rects: if r.grow(50.0).has_point(p): valid = false; break
		if valid: return p
	
	# Fallback: ignore safe zone if desperate
	for i in range(50):
		var p = Vector2(randf_range(50, w - 50), randf_range(50, h - 50))
		var valid = true; for r in inner_rects: if r.grow(30.0).has_point(p): valid = false; break
		if valid: return p

	return Vector2(w/2.0, h/2.0) + Vector2(randf_range(-50, 50), randf_range(-50, 50))

func _spawn_entities(level: int, w: float, h: float, inner_rects: Array) -> void:
	var sz = minf(w, h) * 0.25; var safe_zone = Rect2(w/2.0 - sz, h/2.0 - sz, sz * 2.0, sz * 2.0); portal_instance = portal_scene.instantiate(); portal_instance.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(portal_instance)
	for i in range(cores_required):
		var crystal = crystal_scene.instantiate(); crystal.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(crystal)
	total_coins = 1 + int(floor(level / 2.0))
	for i in range(total_coins):
		var coin = coin_scene.instantiate(); coin.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(coin)
	var num_freezes = 1 if level < 10 else 2
	for i in range(num_freezes):
		var tf = time_freeze_scene.instantiate(); tf.global_position = _get_random_pos(w, h, inner_rects, safe_zone); dynamic_entities.add_child(tf)
	
	var num_enemies = level; var types = ["melee", "ranged", "turret", "patrol"]
	var spawned_count = 0
	for i in range(num_enemies):
		var e = enemy_scene.instantiate(); e.global_position = _get_random_pos(w, h, inner_rects, safe_zone)
		if level <= 2: e.enemy_type = "melee"
		elif level <= 4: e.enemy_type = "melee" if randf() > 0.4 else "patrol"
		elif level <= 7: e.enemy_type = types[randi() % 2] if randf() > 0.3 else "ranged"
		else: e.enemy_type = types[randi() % types.size()]
		if e.enemy_type == "melee": e.move_speed = randf_range(70.0, 85.0 + level * 2.0); e.aggro_range = 400.0 + level * 5.0
		elif e.enemy_type == "ranged": e.shoot_cooldown = maxf(1.0, 2.5 - level * 0.05); e.move_speed = randf_range(50.0, 70.0 + level * 1.5); e.aggro_range = 500.0 + level * 5.0
		elif e.enemy_type == "turret": e.shoot_cooldown = maxf(1.2, 3.0 - level * 0.1); e.aggro_range = 600.0 + level * 10.0
		elif e.enemy_type == "patrol": e.move_speed = randf_range(80.0, 100.0 + level * 2.0)
		dynamic_entities.add_child(e)
		spawned_count += 1
	total_enemies_in_level = spawned_count

func _show_combo_popup(multiplier: int, reward: float) -> void:
	if not combo_label: return
	combo_label.text = "+%.0fs  ×%d" % [reward, multiplier]; combo_label.visible = true; var tw = create_tween(); tw.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.08); tw.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.12)

func _flash_timer_label() -> void:
	if not time_bar: return
	var tw = create_tween(); tw.tween_property(time_bar, "modulate", Color.CYAN * 2.0, 0.15); tw.tween_property(time_bar, "modulate", Color.WHITE * 2.0, 0.25)
