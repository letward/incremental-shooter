extends Control

@onready var money_label: Label = $Panel/VBox/MoneyLabel
@onready var list: VBoxContainer = $Panel/Scroll/List

var rows: Dictionary = {}

func _ready() -> void:
	_style()
	_build_list()
	GameManager.money_changed.connect(_on_money)
	_on_money(GameManager.money)
	# entrance
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _style() -> void:
	var panel = get_node_or_null("Panel")
	if panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.09, 0.12, 0.95)
		sb.corner_radius_top_left = 16
		sb.corner_radius_top_right = 16
		sb.corner_radius_bottom_left = 16
		sb.corner_radius_bottom_right = 16
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.3, 0.4, 0.6, 0.6)
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 12
		panel.add_theme_stylebox_override("panel", sb)

func _build_list() -> void:
	for id in GameManager.upgrades.keys():
		var u = GameManager.upgrades[id]
		var row = HBoxContainer.new()
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl = Label.new()
		name_lbl.text = u["name"]
		var desc_lbl = Label.new()
		desc_lbl.text = u["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.modulate = Color(0.8, 0.8, 0.8)
		info.add_child(name_lbl)
		info.add_child(desc_lbl)
		row.add_child(info)

		var level_lbl = Label.new()
		level_lbl.text = "Lv %d/%d" % [u["level"], u["max"]]
		level_lbl.custom_minimum_size = Vector2(90, 0)
		row.add_child(level_lbl)

		var cost_lbl = Label.new()
		cost_lbl.text = "$%d" % GameManager.upgrade_cost(id)
		cost_lbl.custom_minimum_size = Vector2(80, 0)
		row.add_child(cost_lbl)

		var btn = Button.new()
		btn.text = "Buy"
		btn.custom_minimum_size = Vector2(80, 32)
		var bs = StyleBoxFlat.new()
		bs.bg_color = Color(0.2, 0.5, 0.9, 1)
		bs.corner_radius_top_left = 8
		bs.corner_radius_top_right = 8
		bs.corner_radius_bottom_left = 8
		bs.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", bs)
		var bsh = bs.duplicate()
		bsh.bg_color = Color(0.3, 0.6, 1.0, 1)
		btn.add_theme_stylebox_override("hover", bsh)
		var bsp = bs.duplicate()
		bsp.bg_color = Color(0.15, 0.4, 0.75, 1)
		btn.add_theme_stylebox_override("pressed", bsp)
		btn.pressed.connect(func(): _buy(id))
		btn.mouse_entered.connect(func():
			var t = create_tween()
			t.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.1)
		)
		btn.mouse_exited.connect(func():
			var t = create_tween()
			t.tween_property(btn, "scale", Vector2.ONE, 0.1)
		)
		row.add_child(btn)

		list.add_child(row)
		rows[id] = {"row": row, "level": level_lbl, "cost": cost_lbl, "btn": btn}

func _buy(id: String) -> void:
	if GameManager.buy_upgrade(id):
		AudioManager.play("ui_click")
		_refresh(id)
		# update hud? money_changed handles
	else:
		pass
	_refresh_all()

func _refresh(id: String) -> void:
	var u = GameManager.upgrades[id]
	var r = rows[id]
	r["level"].text = "Lv %d/%d" % [u["level"], u["max"]]
	r["cost"].text = "$%d" % GameManager.upgrade_cost(id)
	r["btn"].disabled = not GameManager.can_upgrade(id)

func _refresh_all() -> void:
	for id in rows.keys():
		_refresh(id)

func _on_money(v: int) -> void:
	money_label.text = "Money: $%d" % v
	_refresh_all()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_menu"):
		# close handled by hud? This node stays; but hud toggles. Ensure mouse mode
		pass
