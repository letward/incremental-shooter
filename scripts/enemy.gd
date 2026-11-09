extends CharacterBody3D

enum Variant { GRUNT, RUNNER, BRUTE }

var variant: int = Variant.GRUNT
var health: float = 30.0
var max_health: float = 30.0
var speed: float = 3.5
var damage: float = 8.0
var attack_range: float = 1.6
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var dead: bool = false
var target: Node3D = null
var money_reward: int = 10

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var body_parts: Dictionary = {}
var health_label: Label3D

func _ready() -> void:
	add_to_group("enemy")
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func setup(v: int, wave: int) -> void:
	variant = v
	_build_model()
	# scale stats by wave
	var w = max(1, wave)
	match variant:
		Variant.GRUNT:
			max_health = 25.0 + w * 6.0
			speed = 3.2 + w * 0.05
			damage = 6.0 + w * 0.4
			money_reward = 10 + w * 2
			attack_range = 1.6
		Variant.RUNNER:
			max_health = 12.0 + w * 3.0
			speed = 5.5 + w * 0.1
			damage = 4.0 + w * 0.3
			money_reward = 8 + w * 2
			attack_range = 1.4
		Variant.BRUTE:
			max_health = 80.0 + w * 18.0
			speed = 2.0 + w * 0.03
			damage = 16.0 + w * 0.8
			money_reward = 30 + w * 4
			attack_range = 2.2
	health = max_health
	if health_label:
		health_label.text = "HP %d" % int(health)

func _build_model() -> void:
	# Collision shape
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	add_child(col)

	# Build humanoid from primitives
	var color: Color
	var scale_factor: float = 1.0
	match variant:
		Variant.GRUNT:
			color = Color(0.85, 0.25, 0.2)
		Variant.RUNNER:
			color = Color(0.95, 0.85, 0.2)
			scale_factor = 0.85
		Variant.BRUTE:
			color = Color(0.5, 0.2, 0.7)
			scale_factor = 1.35
	# but variant may be set after _ready? setup called after. Default grunt color.

	# We'll rebuild color in setup? Instead store variant color later. For now default.
	_build_humanoid(color, scale_factor)

	# Health label
	health_label = Label3D.new()
	health_label.text = "HP %d" % int(health)
	health_label.position = Vector3(0, 2.2, 0)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.font_size = 24
	health_label.modulate = Color(1, 0.3, 0.3)
	add_child(health_label)

func _build_humanoid(color: Color, sf: float) -> void:
	# Legs
	_add_part("leg_l", CapsuleMesh.new(), Vector3(0.22*sf, 0.75*sf, 0.22*sf), Vector3(-0.16*sf, 0.38*sf, 0), color.darkened(0.25))
	_add_part("leg_r", CapsuleMesh.new(), Vector3(0.22*sf, 0.75*sf, 0.22*sf), Vector3(0.16*sf, 0.38*sf, 0), color.darkened(0.25))
	# Knee pads
	_add_part("knee_l", BoxMesh.new(), Vector3(0.24*sf, 0.12*sf, 0.24*sf), Vector3(-0.16*sf, 0.15*sf, -0.05*sf), color.darkened(0.1))
	_add_part("knee_r", BoxMesh.new(), Vector3(0.24*sf, 0.12*sf, 0.24*sf), Vector3(0.16*sf, 0.15*sf, -0.05*sf), color.darkened(0.1))
	# Torso
	_add_part("torso", BoxMesh.new(), Vector3(0.55*sf, 0.75*sf, 0.35*sf), Vector3(0, 1.05*sf, 0), color)
	# Chest plate
	_add_part("chest", BoxMesh.new(), Vector3(0.5*sf, 0.45*sf, 0.12*sf), Vector3(0, 1.15*sf, -0.2*sf), color.lightened(0.05))
	# Belt
	_add_part("belt", BoxMesh.new(), Vector3(0.58*sf, 0.1*sf, 0.38*sf), Vector3(0, 0.7*sf, 0), Color(0.15,0.15,0.18))
	# Backpack
	_add_part("backpack", BoxMesh.new(), Vector3(0.4*sf, 0.5*sf, 0.2*sf), Vector3(0, 1.05*sf, 0.25*sf), Color(0.2,0.22,0.25))
	# Head
	var head = SphereMesh.new()
	head.radius = 0.24*sf
	head.height = 0.48*sf
	_add_part("head", head, Vector3(0.24*sf*2, 0.24*sf*2, 0.24*sf*2), Vector3(0, 1.65*sf, 0), color.lightened(0.1))
	# Helmet
	_add_part("helmet", SphereMesh.new(), Vector3(0.27*sf, 0.2*sf, 0.27*sf), Vector3(0, 1.72*sf, 0), color.darkened(0.15))
	# Eyes / visor
	_add_part("visor", BoxMesh.new(), Vector3(0.34*sf, 0.08*sf, 0.06*sf), Vector3(0, 1.62*sf, -0.2*sf), Color(0.9,0.2,0.1))
	_add_part("eye_l", SphereMesh.new(), Vector3(0.05*sf, 0.05*sf, 0.05*sf), Vector3(-0.09*sf, 1.62*sf, -0.22*sf), Color(1,0.9,0.2))
	_add_part("eye_r", SphereMesh.new(), Vector3(0.05*sf, 0.05*sf, 0.05*sf), Vector3(0.09*sf, 1.62*sf, -0.22*sf), Color(1,0.9,0.2))
	# Arms
	_add_part("arm_l", CapsuleMesh.new(), Vector3(0.2*sf, 0.62*sf, 0.2*sf), Vector3(-0.38*sf, 0.98*sf, 0), color.darkened(0.1))
	_add_part("arm_r", CapsuleMesh.new(), Vector3(0.2*sf, 0.62*sf, 0.2*sf), Vector3(0.38*sf, 0.98*sf, 0), color.darkened(0.1))
	# Shoulder pads
	_add_part("shoulder_l", BoxMesh.new(), Vector3(0.26*sf, 0.18*sf, 0.28*sf), Vector3(-0.42*sf, 1.25*sf, 0), color.darkened(0.05))
	_add_part("shoulder_r", BoxMesh.new(), Vector3(0.26*sf, 0.18*sf, 0.28*sf), Vector3(0.42*sf, 1.25*sf, 0), color.darkened(0.05))
	# Weapon in hand
	var weapon_color = Color(0.18,0.18,0.22)
	var weapon_size = Vector3(0.12*sf, 0.12*sf, 0.7*sf)
	if variant == Variant.BRUTE:
		weapon_size = Vector3(0.18*sf, 0.18*sf, 1.1*sf)
		weapon_color = Color(0.35,0.1,0.1)
	_add_part("weapon", BoxMesh.new(), weapon_size, Vector3(0.45*sf, 0.95*sf, -0.25*sf), weapon_color)
	# muzzle tip
	_add_part("weapon_tip", BoxMesh.new(), Vector3(0.08*sf, 0.08*sf, 0.15*sf), Vector3(0.45*sf, 0.95*sf, -0.65*sf), Color(0.1,0.1,0.1))

func _add_part(name: String, mesh: Mesh, size: Vector3, pos: Vector3, color: Color) -> void:
	var mi = MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	# set mesh size via resource properties if possible
	if mesh is BoxMesh:
		mesh.size = size
	elif mesh is SphereMesh:
		mesh.radius = size.x * 0.5
		mesh.height = size.y
	elif mesh is CapsuleMesh:
		mesh.radius = size.x * 0.5
		mesh.height = size.y
	mi.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mi.material_override = mat
	add_child(mi)

func _physics_process(delta: float) -> void:
	if dead:
		return
	# update health label (all peers)
	if health_label:
		health_label.text = "HP %d" % int(health)
	if not multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		return
	if target == null or not is_instance_valid(target):
		return
	attack_timer = max(0, attack_timer - delta)
	var to_target = target.global_position - global_position
	to_target.y = 0
	var dist = to_target.length()
	if dist > attack_range:
		var dir = to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
		if attack_timer <= 0:
			attack_timer = attack_cooldown
			if target.has_method("take_damage"):
				target.take_damage(damage)
	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	move_and_slide()
	# face target
	if dist > 0.1:
		var look = target.global_position
		look.y = global_position.y
		look_at(look, Vector3.UP)

	# update health label
	if health_label:
		health_label.text = "HP %d" % int(health)

@rpc("any_peer", "reliable")
func take_damage(amount: float, from_peer: int = 0) -> void:
	if not multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		return
	if dead:
		return
	health -= amount
	AudioManager.play("hit", -6.0, randf_range(0.9, 1.1))
	_flash_hit()
	if health_label:
		health_label.text = "HP %d" % int(health)
	if health <= 0:
		die()

func _spawn_death_burst() -> void:
	var color = Color(0.9, 0.3, 0.2)
	for i in range(12):
		var mi = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		mi.mesh = sm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
		mi.material_override = mat
		get_tree().current_scene.add_child(mi)
		mi.global_position = global_position + Vector3(0, 1.0, 0)
		var dir = Vector3(randf_range(-1,1), randf_range(0.5,2), randf_range(-1,1)).normalized()
		var tw = mi.create_tween()
		tw.set_parallel(true)
		tw.tween_property(mi, "global_position", mi.global_position + dir * randf_range(2,4), 0.6)
		tw.tween_property(mi, "scale", Vector3.ZERO, 0.6)
		tw.tween_callback(mi.queue_free)

func _flash_hit() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.08, 1.08, 1.08), 0.05)
	tw.tween_property(self, "scale", Vector3.ONE, 0.1)

func die() -> void:
	if dead:
		return
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	dead = true
	if multiplayer.has_multiplayer_peer():
		GameManager.rpc_add_kill()
	else:
		GameManager.add_kill()
	if multiplayer.has_multiplayer_peer():
		GameManager.rpc_add_money(money_reward)
	else:
		GameManager.add_money(money_reward)
	AudioManager.play("enemy_death", -4.0)
	AudioManager.play("pickup", -8.0, randf_range(0.9, 1.1))
	# death burst particles
	_spawn_death_burst()
	# death effect: shrink
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.3)
	tw.tween_callback(queue_free)
	# spawn money popup? skip
	# remove from group
	remove_from_group("enemy")
	GameManager.enemies_alive = max(0, GameManager.enemies_alive - 1)
	# notify spawner via signal? Spawner polls count
