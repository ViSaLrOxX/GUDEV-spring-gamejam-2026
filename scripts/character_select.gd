extends Control

const CharacterData = preload("res://scripts/character_data.gd")

var _selected_index : int = 0
var _cards          : Array = []
var _detail_name    : Label
var _detail_title   : Label
var _detail_story   : Label
var _detail_ability : Label
var _detail_desc    : Label
var _confirm_btn    : Button
var _portrait_slot  : Control

func _ready() -> void:
	_build_ui()
	_refresh_detail()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.06)
	add_child(bg)

	var title := Label.new()
	title.text = "SELECT OPERATIVE"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0) * 2.5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 18.0
	title.offset_bottom = 62.0
	add_child(title)

	var chars: Array = CharacterData.get_all()

	var main_row := HBoxContainer.new()
	main_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_row.offset_top = 70.0
	main_row.offset_bottom = -70.0
	main_row.offset_left = 20.0
	main_row.offset_right = -20.0
	main_row.add_theme_constant_override("separation", 16)
	add_child(main_row)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(220, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_row.add_child(scroll)

	var card_col := VBoxContainer.new()
	card_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_col.add_theme_constant_override("separation", 8)
	scroll.add_child(card_col)

	for i in range(chars.size()):
		var c: Dictionary = chars[i]
		var card := Button.new()
		card.custom_minimum_size = Vector2(200, 72)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.08, 0.12)
		style.border_color = c["colour"]
		style.border_width_left = 3
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.content_margin_left = 12
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		card.add_theme_stylebox_override("normal", style)
		card.add_theme_stylebox_override("hover", style)
		card.add_theme_stylebox_override("pressed", style)
		card.add_theme_stylebox_override("focus", style)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(row)

		var thumb_holder := CenterContainer.new()
		thumb_holder.custom_minimum_size = Vector2(48, 48)
		row.add_child(thumb_holder)

		var tex_path: String = c.get("image_path", "")
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tr := TextureRect.new()
			tr.texture = load(tex_path)
			tr.custom_minimum_size = Vector2(48, 48)
			tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumb_holder.add_child(tr)
		else:
			var cr := ColorRect.new()
			cr.custom_minimum_size = Vector2(44, 44)
			cr.color = c["colour"] * 0.6
			thumb_holder.add_child(cr)

		var label_col := VBoxContainer.new()
		label_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(label_col)

		var name_lbl := Label.new()
		name_lbl.text = c["name"]
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", c["colour"] * 2.5)
		label_col.add_child(name_lbl)

		var title_lbl := Label.new()
		title_lbl.text = c["title"]
		title_lbl.add_theme_font_size_override("font_size", 10)
		title_lbl.add_theme_color_override("font_color", Color.WHITE * 0.55)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		label_col.add_child(title_lbl)

		var idx := i
		card.pressed.connect(func():
			_selected_index = idx
			_refresh_cards()
			_refresh_detail()
		)
		_cards.append(card)
		card_col.add_child(card)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var dp_style := StyleBoxFlat.new()
	dp_style.bg_color = Color(0.06, 0.06, 0.10)
	dp_style.border_color = Color(0.2, 0.8, 1.0) * 0.6
	dp_style.border_width_left = 1
	dp_style.border_width_top = 1
	dp_style.border_width_right = 1
	dp_style.border_width_bottom = 1
	dp_style.content_margin_left = 20
	dp_style.content_margin_right = 20
	dp_style.content_margin_top = 16
	dp_style.content_margin_bottom = 16
	detail_panel.add_theme_stylebox_override("panel", dp_style)
	main_row.add_child(detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 10)
	detail_panel.add_child(detail_vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	detail_vbox.add_child(top_row)

	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(130, 130)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.08, 0.13)
	p_style.border_color = Color(0.2, 0.8, 1.0) * 0.4
	p_style.border_width_left = 1
	p_style.border_width_top = 1
	p_style.border_width_right = 1
	p_style.border_width_bottom = 1
	portrait_container.add_theme_stylebox_override("panel", p_style)
	portrait_container.name = "PortraitContainer"
	top_row.add_child(portrait_container)

	_portrait_slot = CenterContainer.new()
	_portrait_slot.name = "PortraitSlot"
	_portrait_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_container.add_child(_portrait_slot)

	var name_col := VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.alignment = BoxContainer.ALIGNMENT_CENTER
	name_col.add_theme_constant_override("separation", 4)
	top_row.add_child(name_col)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 38)
	name_col.add_child(_detail_name)

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 14)
	_detail_title.add_theme_color_override("font_color", Color.WHITE * 0.55)
	name_col.add_child(_detail_title)

	var ability_box := PanelContainer.new()
	var ab_style := StyleBoxFlat.new()
	ab_style.bg_color = Color(0.05, 0.08, 0.05)
	ab_style.border_color = Color.YELLOW * 0.5
	ab_style.border_width_left = 2
	ab_style.border_width_top = 0
	ab_style.border_width_right = 0
	ab_style.border_width_bottom = 0
	ab_style.content_margin_left = 12
	ab_style.content_margin_right = 12
	ab_style.content_margin_top = 8
	ab_style.content_margin_bottom = 8
	ability_box.add_theme_stylebox_override("panel", ab_style)
	detail_vbox.add_child(ability_box)

	var ability_vbox := VBoxContainer.new()
	ability_vbox.add_theme_constant_override("separation", 3)
	ability_box.add_child(ability_vbox)

	_detail_ability = Label.new()
	_detail_ability.add_theme_font_size_override("font_size", 17)
	_detail_ability.add_theme_color_override("font_color", Color.YELLOW * 2.2)
	ability_vbox.add_child(_detail_ability)

	_detail_desc = Label.new()
	_detail_desc.add_theme_font_size_override("font_size", 14)
	_detail_desc.add_theme_color_override("font_color", Color.WHITE * 0.8)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	ability_vbox.add_child(_detail_desc)

	var story_scroll := ScrollContainer.new()
	story_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_vbox.add_child(story_scroll)

	_detail_story = Label.new()
	_detail_story.add_theme_font_size_override("font_size", 15)
	_detail_story.add_theme_color_override("font_color", Color.WHITE * 0.75)
	_detail_story.autowrap_mode = TextServer.AUTOWRAP_WORD
	_detail_story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_scroll.add_child(_detail_story)

	_confirm_btn = Button.new()
	_confirm_btn.text = "DEPLOY OPERATIVE"
	_confirm_btn.custom_minimum_size = Vector2(0, 52)
	_confirm_btn.add_theme_font_size_override("font_size", 22)
	_confirm_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_confirm_btn.offset_top = -62.0
	_confirm_btn.offset_bottom = -8.0
	_confirm_btn.offset_left = 20.0
	_confirm_btn.offset_right = -20.0

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.05, 0.18, 0.28)
	btn_style.border_color = Color(0.2, 0.8, 1.0) * 1.5
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.skew = Vector2(0.08, 0.0)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.1, 0.3, 0.5)
	btn_hover.border_color = Color(0.2, 0.8, 1.0) * 3.0
	_confirm_btn.add_theme_stylebox_override("normal", btn_style)
	_confirm_btn.add_theme_stylebox_override("hover", btn_hover)
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

	_refresh_cards()

func _refresh_cards() -> void:
	var chars: Array = CharacterData.get_all()
	for i in range(_cards.size()):
		var style := StyleBoxFlat.new()
		var is_sel := i == _selected_index
		style.bg_color = Color(0.14, 0.14, 0.20) if is_sel else Color(0.08, 0.08, 0.12)
		style.border_color = chars[i]["colour"] * (3.0 if is_sel else 1.0)
		style.border_width_left = 4 if is_sel else 3
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.content_margin_left = 12
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		_cards[i].add_theme_stylebox_override("normal", style)
		_cards[i].add_theme_stylebox_override("hover", style)

func _refresh_detail() -> void:
	var chars: Array = CharacterData.get_all()
	var c: Dictionary = chars[_selected_index]

	_detail_name.text = c["name"]
	_detail_name.add_theme_color_override("font_color", c["colour"] * 3.0)
	_detail_title.text = c["title"]
	_detail_story.text = c["backstory"]

	if c["ability_type"] != "none":
		_detail_ability.text = c["ability_name"]
		_detail_desc.text = c["ability_desc"]
	else:
		_detail_ability.text = "NO ABILITY"
		_detail_desc.text = "No special power. Just you and your aim."

	if _portrait_slot:
		for child in _portrait_slot.get_children():
			child.queue_free()
		var tex_path: String = c.get("image_path", "")
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tr := TextureRect.new()
			tr.texture = load(tex_path)
			tr.custom_minimum_size = Vector2(120, 120)
			tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_portrait_slot.add_child(tr)
		else:
			var cr := ColorRect.new()
			cr.custom_minimum_size = Vector2(120, 120)
			cr.color = c["colour"] * 0.4
			_portrait_slot.add_child(cr)

func _on_confirm() -> void:
	var chars: Array = CharacterData.get_all()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs:
		gs.selected_character = chars[_selected_index]["id"]
	get_tree().change_scene_to_file("res://scenes/game.tscn")
