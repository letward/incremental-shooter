extends CanvasLayer

@onready var health_bar: ProgressBar = $TopLeft/HealthBar
@onready var ammo_label: Label = $TopLeft/AmmoLabel
@onready var money_label: Label = $TopRight/MoneyLabel
@onready var kills_label: Label = $TopRight/KillsLabel
@onready var wave_label: Label = $TopRight/WaveLabel
@onready var msg_label: Label = $MsgLabel
@onready var damage_flash: ColorRect = $DamageFlash

var upgrade_menu: Control = null
var displayed_money: int = 0
var displayed_health: float = 100.0
var prev_health: float = 100.0
var health_tween: Tween
var money_tween: Tween

func _ready() -> void:
	_style_ui()
	GameManager.money_changed.connect(_on_money)
	GameManager.kills_changed.connect(_on_kills)
	GameManager.wave_changed.connect(_on_wave)
	GameManager.health_changed.connect(_on_health)
	GameManager.ammo_changed.connect(_on_ammo)
	_on_money(GameManager.money)
	_on_kills(GameManager.kills)
	_on_wave(GameManager.wave)
	health_bar.value = GameManager.max_health() if false else 100.0
	displayed_health = health_bar.value
	await get_tree().process_frame
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_signal("died"):
		p.died.connect(func(): show_msg("You died! Respawning...", 2.0))

func _style_ui() -> void:
	# Rounded health bar
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.85)
	bg.corner_radius_top_left = 10
	bg.corner_radius_top_right = 10
	bg.corner_radius_bottom_left = 10
	bg.corner_radius_bottom_right = 10
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.18, 0.22, 1)
	fill.corner_radius_top_left = 10
	fill.corner_radius_top_right = 10
	fill.corner_radius_bottom_left = 10
	fill.corner_radius_bottom_right = 10
	health_bar.add_theme_stylebox_override("background", bg)
	health_bar.add_theme_stylebox_override("fill", fill)

	# Rounded panels via modulate glow not needed
	money_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

func _on_money(v: int) -> void:
	if money_tween and money_tween.is_valid():
		money_tween.kill()
	money_tween = create_tween()
	money_tween.tween_method(func(val): 
		displayed_money = int(val)
		money_label.text = "Money: $%d" % displayed_money
	, displayed_money, v, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# bounce
	var tw = create_tween()
	tw.tween_property(money_label, "scale", Vector2(1.15, 1.15), 0.1)
	tw.tween_property(money_label, "scale", Vector2.ONE, 0.15)

func _on_kills(v: int) -> void:
	kills_label.text = "Kills: %d" % v

func _on_wave(v: int) -> void:
	wave_label.text = "Wave: %d" % v
	show_msg("Wave %d incoming!" % v)

func _on_health(cur: float, mx: float) -> void:
	health_bar.max_value = mx
	# damage flash
	if cur < prev_health - 0.1:
		_flash_damage()
	prev_health = cur
	if health_tween and health_tween.is_valid():
		health_tween.kill()
	health_tween = create_tween()
	health_tween.tween_property(health_bar, "value", cur, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# color shift
	var fill = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		var ratio = cur / mx
		if ratio > 0.5:
			fill.bg_color = Color(0.2, 0.85, 0.35, 1)
		elif ratio > 0.25:
			fill.bg_color = Color(0.95, 0.75, 0.2, 1)
		else:
			fill.bg_color = Color(0.9, 0.15, 0.2, 1)

func _flash_damage() -> void:
	damage_flash.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(damage_flash, "modulate:a", 0.5, 0.05)
	tw.tween_property(damage_flash, "modulate:a", 0.0, 0.35)

func _on_ammo(cur: int, mx: int, res: int) -> void:
	ammo_label.text = "Ammo: %d / %d  (reserve %d)" % [cur, mx, res]

func show_msg(text: String, dur: float = 2.0) -> void:
	msg_label.text = text
	msg_label.modulate.a = 1.0
	msg_label.scale = Vector2(0.8, 0.8)
	var tw = create_tween()
	tw.tween_property(msg_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(dur)
	tw.tween_property(msg_label, "modulate:a", 0.0, 0.5)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_menu"):
		_toggle_upgrade_menu()

func _toggle_upgrade_menu() -> void:
	if upgrade_menu == null:
		var scene = load("res://scenes/upgrade_menu.tscn")
		if scene:
			upgrade_menu = scene.instantiate()
			add_child(upgrade_menu)
			upgrade_menu.modulate.a = 0.0
			upgrade_menu.scale = Vector2(0.9, 0.9)
			var tw = create_tween()
			tw.set_parallel(true)
			tw.tween_property(upgrade_menu, "modulate:a", 1.0, 0.2)
			tw.tween_property(upgrade_menu, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		var tw = create_tween()
		tw.tween_property(upgrade_menu, "modulate:a", 0.0, 0.15)
		tw.tween_callback(func():
			if is_instance_valid(upgrade_menu):
				upgrade_menu.queue_free()
				upgrade_menu = null
		)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED