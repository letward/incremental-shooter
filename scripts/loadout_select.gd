extends Control

@onready var list: VBoxContainer = $Center/VBox/List
@onready var info_label: Label = $Center/VBox/Info/InfoLabel
@onready var confirm_btn: Button = $Center/VBox/ConfirmBtn

var selected_btn: Button = null
var buttons: Dictionary = {}

func _ready() -> void:
	_style_confirm()
	_build_list()
	_select(LoadoutManager.selected)
	confirm_btn.pressed.connect(_confirm)

func _style_confirm() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.5, 0.9, 1)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	confirm_btn.add_theme_stylebox_override("normal", sb)
	var sh = sb.duplicate()
	sh.bg_color = Color(0.3, 0.6, 1.0, 1)
	confirm_btn.add_theme_stylebox_override("hover", sh)
	confirm_btn.add_theme_font_size_override("font_size", 18)

func _build_list() -> void:
	for id in LoadoutManager.loadouts.keys():
		var L = LoadoutManager.loadouts[id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 56)
		btn.text = L["name"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# color strip via modulate? Use text only
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.12, 0.18, 0.9)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		sb.border_width_left = 4
		sb.border_color = L["color"]
		btn.add_theme_stylebox_override("normal", sb)
		var sh = sb.duplicate()
		sh.bg_color = Color(0.15, 0.18, 0.26, 0.95)
		btn.add_theme_stylebox_override("hover", sh)
		btn.pressed.connect(func(): _select(id))
		list.add_child(btn)
		buttons[id] = btn

func _select(id: String) -> void:
	LoadoutManager.selected = id
	var L = LoadoutManager.get_selected()
	# highlight
	for key in buttons.keys():
		var b = buttons[key]
		var sb = b.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			if key == id:
				sb.border_width_left = 6
				sb.bg_color = Color(0.18, 0.25, 0.35, 0.95)
			else:
				sb.border_width_left = 4
				sb.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	info_label.text = "%s\n%s\nDamage: %.0f | Fire Rate: %.2fs | Mag: %d | Range: %.0f" % [L["name"], L["desc"], L["damage"], L["interval"], L["mag"], L["range"]]
	info_label.modulate = L["color"].lightened(0.3)

func _confirm() -> void:
	AudioManager.play("ui_click")
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(_go_to_game)

func _go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")