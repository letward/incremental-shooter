extends CharacterBody3D

@export var mouse_sensitivity: float = 0.0018

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D
var weapon: Node
var health: float = 100.0
var max_health: float = 100.0
var armor: float = 0.0
var dead: bool = false
var invuln: float = 0.0

signal died

func _ready() -> void:
	add_to_group("player")
	camera = get_node_or_null("Camera3D")
	weapon = get_node_or_null("Camera3D/Weapon")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	max_health = GameManager.max_health()
	health = max_health
	GameManager.health_changed.emit(health, max_health)
	GameManager.upgrade_purchased.connect(_on_upgrade)

func _on_upgrade(id: String) -> void:
	if id == "max_health":
		var old_max = max_health
		max_health = GameManager.max_health()
		health = min(health + (max_health - old_max), max_health)
		GameManager.health_changed.emit(health, max_health)
	if id == "armor":
		armor = GameManager.armor_reduction()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if camera:
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -1.4, 1.4)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if dead:
		return
	if invuln > 0:
		invuln -= delta
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 4.5
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var spd = GameManager.move_speed()
	if Input.is_action_pressed("sprint"):
		spd *= 1.45
	if direction:
		velocity.x = direction.x * spd
		velocity.z = direction.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0, spd)
		velocity.z = move_toward(velocity.z, 0, spd)
	move_and_slide()

	# shooting handled by weapon node reading input

func take_damage(amount: float) -> void:
	if dead or invuln > 0:
		return
	var red = GameManager.armor_reduction()
	var dmg = amount * (1.0 - red)
	health -= dmg
	invuln = 0.15
	AudioManager.play("player_hurt", -4.0)
	# damage flash via camera shake
	_camera_shake()
	GameManager.health_changed.emit(health, max_health)
	if health <= 0:
		health = 0
		dead = true
		died.emit()
		# respawn after short delay
		await get_tree().create_timer(2.0).timeout
		respawn()

func respawn() -> void:
	dead = false
	health = max_health
	global_position = Vector3(0, 1.5, 0)
	velocity = Vector3.ZERO
	GameManager.health_changed.emit(health, max_health)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _camera_shake_small() -> void:
	if camera == null:
		return
	var orig = camera.rotation
	var tw = create_tween()
	tw.tween_property(camera, "rotation", orig + Vector3(0.012, 0, 0), 0.03)
	tw.tween_property(camera, "rotation", orig, 0.08)

func _camera_shake() -> void:
	if camera == null:
		return
	var orig = camera.rotation
	var tw = create_tween()
	tw.tween_property(camera, "rotation", orig + Vector3(0.03, 0, 0), 0.05)
	tw.tween_property(camera, "rotation", orig - Vector3(0.02, 0.01, 0), 0.05)
	tw.tween_property(camera, "rotation", orig, 0.1)

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	GameManager.health_changed.emit(health, max_health)
