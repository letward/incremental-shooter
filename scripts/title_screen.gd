extends Control

@onready var start_btn: Button = $Center/VBox/StartBtn
@onready var title1: Label = $Center/VBox/Title1
@onready var title2: Label = $Center/VBox/Title2
@onready var crosshair: Control = $Center/VBox/Crosshair

func _ready() -> void:
	_style_button()
	_animate_entrance()
	start_btn.pressed.connect(_start_game)

func _style_button() -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.5, 0.9, 1)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	start_btn.add_theme_stylebox_override("normal", sb)
	var sh = sb.duplicate()
	sh.bg_color = Color(0.3, 0.6, 1.0, 1)
	start_btn.add_theme_stylebox_override("hover", sh)
	var sp = sb.duplicate()
	sp.bg_color = Color(0.15, 0.4, 0.75, 1)
	start_btn.add_theme_stylebox_override("pressed", sp)
	start_btn.add_theme_font_size_override("font_size", 20)

func _animate_entrance() -> void:
	title1.modulate.a = 0.0
	title2.modulate.a = 0.0
	crosshair.modulate.a = 0.0
	start_btn.modulate.a = 0.0
	title1.position.y += 40
	title2.position.y += 40
	crosshair.scale = Vector2(0.5, 0.5)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(crosshair, "modulate:a", 1.0, 0.4)
	tw.tween_property(crosshair, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title1, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tw.tween_property(title1, "position:y", title1.position.y - 40, 0.5).set_delay(0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(title2, "modulate:a", 1.0, 0.5).set_delay(0.35)
	tw.tween_property(title2, "position:y", title2.position.y - 40, 0.5).set_delay(0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(start_btn, "modulate:a", 1.0, 0.4).set_delay(0.7)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_start_game()

func _start_game() -> void:
	AudioManager.play("ui_click")
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_go_to_game)

func _go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/loadout_select.tscn")
