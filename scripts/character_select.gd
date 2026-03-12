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
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0) * 2.5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40.0
	title.offset_bottom = 100.0
	add_child(title)

	var chars := CharacterData.get_all()

	var card_row := HBoxContainer.new()
	card_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	card_row.offset_top    = 110.0
	card_row.offset_bottom = 280.0
	card_row.offset_left   = 60.0
	card_row.offset_right  = -60.0
	card_row.add_theme_constant_override("separation", 12)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(card_row)

	for i in range(chars.size()):
		var c      := chars[i]
		var card   := Button.new()
		card.custom_minimum_size = Vector2(160, 160)
		var style  := StyleBoxFlat.new()
		style.bg_color       = Color(0.08, 0.08, 0.12)
		style.border_color   = c["colour"]
		style.border_width_left = 2; style.border_width_top = 2
		style.border_width_right = 2; style.border_width_bottom = 2
		style.skew = Vector2(0.15, 0.0)
		card.add_theme_stylebox_override("normal",   style)
		card.add_theme_stylebox_override("hover",    style)
		card.add_theme_stylebox_override("pressed",  style)
		card.add_theme_stylebox_override("focus",    style)

		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(vb)

		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(60, 60)
		icon.color = c["colour"] * 0.8
		var icon_holder := CenterContainer.new()
		icon_holder.add_child(icon)
		vb.add_child(icon_holder)

		var name_label := Label.new()
		name_label.text = c["name"]
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", c["colour"] * 2.5)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(name_label)

		var title_label := Label.new()
		title_label.text = c["title"]
		title_label.add_theme_font_size_override("font_size", 10)
		title_label.add_theme_color_override("font_color", Color.WHITE * 0.7)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(title_label)

		var idx := i
		card.pressed.connect(func():
			_selected_index = idx
			_refresh_cards()
			_refresh_detail()
		)
		_cards.append(card)
		card_row.add_child(card)

	var detail_panel := PanelContainer.new()
	detail_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	detail_panel.offset_top    = -400.0
	detail_panel.offset_bottom = -80.0
	detail_panel.offset_left   = 80.0
	detail_panel.offset_right  = -80.0
	add_child(detail_panel)

	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 12)
	detail_panel.add_child(dv)

	_detail_name  = Label.new(); _detail_name.add_theme_font_size_override("font_size", 40); dv.add_child(_detail_name)
	_detail_title = Label.new(); _detail_title.add_theme_font_size_override("font_size", 18); _detail_title.add_theme_color_override("font_color", Color.WHITE * 0.6); dv.add_child(_detail_title)
	dv.add_child(HSeparator.new())
	_detail_story = Label.new(); _detail_story.add_theme_font_size_override("font_size", 16); _detail_story.autowrap_mode = TextServer.AUTOWRAP_WORD; dv.add_child(_detail_story)
	dv.add_child(HSeparator.new())

	var ability_row := HBoxContainer.new()
	_detail_ability = Label.new(); _detail_ability.add_theme_font_size_override("font_size", 20); _detail_ability.add_theme_color_override("font_color", Color.YELLOW * 2.0); ability_row.add_child(_detail_ability)
	_detail_desc = Label.new(); _detail_desc.add_theme_font_size_override("font_size", 16); _detail_desc.add_theme_color_override("font_color", Color.WHITE * 0.8); ability_row.add_child(_detail_desc)
	dv.add_child(ability_row)

	_confirm_btn = Button.new()
	_confirm_btn.text = "DEPLOY OPERATIVE"
	_confirm_btn.custom_minimum_size = Vector2(300, 60)
	_confirm_btn.add_theme_font_size_override("font_size", 28)
	_confirm_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_confirm_btn.offset_top    = -72.0
	_confirm_btn.offset_bottom = -10.0
	_confirm_btn.offset_left   = 400.0
	_confirm_btn.offset_right  = -400.0
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

	_refresh_cards()

func _refresh_cards() -> void:
	var chars := CharacterData.get_all()
	for i in range(_cards.size()):
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.16, 0.22) if i == _selected_index else Color(0.08, 0.08, 0.12)
		style.border_color = chars[i]["colour"] * (3.0 if i == _selected_index else 1.0)
		style.border_width_left = 3 if i == _selected_index else 2
		style.border_width_top  = 3 if i == _selected_index else 2
		style.border_width_right  = 3 if i == _selected_index else 2
		style.border_width_bottom = 3 if i == _selected_index else 2
		style.skew = Vector2(0.15, 0.0)
		_cards[i].add_theme_stylebox_override("normal", style)
		_cards[i].add_theme_stylebox_override("hover",  style)

func _refresh_detail() -> void:
	var chars := CharacterData.get_all()
	var c     := chars[_selected_index]
	_detail_name.text  = c["name"]
	_detail_name.add_theme_color_override("font_color", c["colour"] * 3.0)
	_detail_title.text = c["title"]
	_detail_story.text = c["backstory"]
	_detail_ability.text = "ABILITY: %s  —  " % c["ability_name"] if c["ability_type"] != "none" else ""
	_detail_desc.text  = c["ability_desc"]

func _on_confirm() -> void:
	var chars  := CharacterData.get_all()
	var gs     := get_node_or_null("/root/GameState")
	if gs:
		gs.selected_character = chars[_selected_index]["id"]
	get_tree().change_scene_to_file("res://scenes/game.tscn")
