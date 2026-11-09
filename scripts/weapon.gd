extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var current_ammo: int = 30
var reserve: int = 90
var reloading: bool = false
var reload_timer: float = 0.0
var fire_cooldown: float = 0.0
var muzzle_flash_timer: float = 0.0

@onready var muzzle: Node3D = get_node_or_null("Muzzle")
@onready var mesh: MeshInstance3D = get_node_or_null("Mesh")

func _ready() -> void:
	player = get_parent().get_parent() if get_parent() else null
	# player is CharacterBody3D? path Camera3D/Weapon -> parent Camera3D -> parent player
	if get_parent() and get_parent().get_parent():
		player = get_parent().get_parent()
	camera = get_parent() as Camera3D
	_sync_ammo()

func _sync_ammo() -> void:
	GameManager.ammo_changed.emit(current_ammo, GameManager.mag_size(), reserve)

func _process(delta: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= delta
	if reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			_finish_reload()
	if muzzle_flash_timer > 0:
		muzzle_flash_timer -= delta
		if muzzle and muzzle.has_node("Flash"):
			muzzle.get_node("Flash").visible = muzzle_flash_timer > 0

	# reload input
	if Input.is_action_just_pressed("reload") and not reloading and current_ammo < GameManager.mag_size():
		_start_reload()

	# shooting
	if Input.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if not reloading and fire_cooldown <= 0:
			if current_ammo > 0:
				_fire()
				AudioManager.play("shoot")
			else:
				AudioManager.play("empty")
				_start_reload()

func _fire() -> void:
	current_ammo -= 1
	fire_cooldown = GameManager.fire_interval()
	_sync_ammo()
	# muzzle flash
	muzzle_flash_timer = 0.06
	if muzzle and muzzle.has_node("Flash"):
		muzzle.get_node("Flash").visible = true

	# raycast from camera center
	if camera == null:
		return
	var from = camera.global_position
	var dir = -camera.global_transform.basis.z
	var to = from + dir * 100.0
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player.get_rid()] if player else []
	var result = space.intersect_ray(query)
	if result:
		var collider = result.collider
		var hit_pos = result.position
		_spawn_impact(hit_pos, result.normal)
		if collider and collider.has_method("take_damage"):
			var dmg = 10.0 * GameManager.damage_mult()
			collider.take_damage(dmg, player)
			# lifesteal
			var ls = GameManager.lifesteal()
			if ls > 0 and player:
				player.heal(dmg * ls)
		# recoil
	var tw = create_tween()
	tw.tween_property(self, "position", Vector3(0.35, -0.25, -0.35), 0.04)
	tw.tween_property(self, "position", Vector3(0.35, -0.25, -0.5), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# camera shake small
	if player and player.has_method("_camera_shake_small"):
		player._camera_shake_small()

func _start_reload() -> void:
	if reserve <= 0 and current_ammo >= GameManager.mag_size():
		return
	reloading = true
	reload_timer = GameManager.reload_time()
	AudioManager.play("reload")

func _finish_reload() -> void:
	reloading = false
	var cap = GameManager.mag_size()
	var need = cap - current_ammo
	var take = min(need, reserve)
	# infinite reserve: if reserve insufficient, just fill (give ammo)
	if take < need:
		take = need
		reserve = max(reserve, 0)
	current_ammo += take
	reserve = max(0, reserve - take)
	_sync_ammo()

func _spawn_impact(pos: Vector3, normal: Vector3) -> void:
	var dot = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	dot.mesh = sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.6, 0.1)
	mat.emission_energy_multiplier = 2.0
	dot.material_override = mat
	get_tree().current_scene.add_child(dot)
	dot.global_position = pos
	# fade out
	var tw = dot.create_tween()
	tw.tween_property(dot, "scale", Vector3.ZERO, 0.25)
	tw.tween_callback(dot.queue_free)
