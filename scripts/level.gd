extends Node3D

func _ready() -> void:
	_build()

func _mat(color: Color, rough: float = 0.8, emit: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	if emit > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	return m

func _box(parent: Node, size: Vector3, pos: Vector3, color: Color, collide: bool = true) -> void:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _mat(color)
	parent.add_child(mi)
	if collide:
		var sb = StaticBody3D.new()
		sb.position = pos
		var cs = CollisionShape3D.new()
		var bs = BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		parent.add_child(sb)

func _cyl(parent: Node, radius: float, height: float, pos: Vector3, color: Color, collide: bool = true) -> void:
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.position = pos
	mi.material_override = _mat(color)
	parent.add_child(mi)
	if collide:
		var sb = StaticBody3D.new()
		sb.position = pos
		var cs = CollisionShape3D.new()
		var cs_shape = CylinderShape3D.new()
		cs_shape.radius = radius
		cs_shape.height = height
		cs.shape = cs_shape
		sb.add_child(cs)
		parent.add_child(sb)

func _build() -> void:
	var floor_color = Color(0.18, 0.2, 0.24)
	var wall_color = Color(0.28, 0.3, 0.36)
	var accent = Color(0.2, 0.5, 0.9)
	var crate_color = Color(0.55, 0.4, 0.25)
	var metal = Color(0.4, 0.42, 0.48)

	# Main floor
	_box(self, Vector3(60, 1, 60), Vector3(0, -0.5, 0), floor_color)
	# Floor grid lines (visual)
	for i in range(-6, 7):
		_box(self, Vector3(60, 0.02, 0.1), Vector3(0, 0.01, i*5), Color(0.25,0.28,0.32), false)
		_box(self, Vector3(0.1, 0.02, 60), Vector3(i*5, 0.01, 0), Color(0.25,0.28,0.32), false)

	# Outer walls
	var h = 6.0
	_box(self, Vector3(60, h, 1), Vector3(0, h/2, -30), wall_color)
	_box(self, Vector3(60, h, 1), Vector3(0, h/2, 30), wall_color)
	_box(self, Vector3(1, h, 60), Vector3(-30, h/2, 0), wall_color)
	_box(self, Vector3(1, h, 60), Vector3(30, h/2, 0), wall_color)

	# Accent strips on walls
	_box(self, Vector3(60, 0.3, 0.15), Vector3(0, 1.5, -29.6), accent, false)
	_box(self, Vector3(60, 0.3, 0.15), Vector3(0, 1.5, 29.6), accent, false)

	# Central platform (raised)
	_box(self, Vector3(12, 1.2, 12), Vector3(0, 0.6, 0), metal)
	# ramps
	_box(self, Vector3(4, 0.6, 6), Vector3(0, 0.3, 9), metal)
	_box(self, Vector3(4, 0.6, 6), Vector3(0, 0.3, -9), metal)
	_box(self, Vector3(6, 0.6, 4), Vector3(9, 0.3, 0), metal)
	_box(self, Vector3(6, 0.6, 4), Vector3(-9, 0.3, 0), metal)

	# Pillars
	for p in [Vector3(10,0,10), Vector3(-10,0,10), Vector3(10,0,-10), Vector3(-10,0,-10), Vector3(18,0,0), Vector3(-18,0,0), Vector3(0,0,18), Vector3(0,0,-18)]:
		_cyl(self, 0.6, 5.0, Vector3(p.x, 2.5, p.z), wall_color)

	# Cover crates
	var crates = [Vector3(6,0.75,6), Vector3(-6,0.75,6), Vector3(6,0.75,-6), Vector3(-6,0.75,-6),
		Vector3(14,0.75,4), Vector3(-14,0.75,4), Vector3(14,0.75,-4), Vector3(-14,0.75,-4),
		Vector3(4,0.75,14), Vector3(-4,0.75,14), Vector3(4,0.75,-14), Vector3(-4,0.75,-14)]
	for c in crates:
		_box(self, Vector3(1.5, 1.5, 1.5), c, crate_color)

	# Second floor balcony (north)
	_box(self, Vector3(20, 0.5, 8), Vector3(0, 4.0, -22), metal)
	# support pillars for balcony
	for x in [-8.0, 0.0, 8.0]:
		_cyl(self, 0.4, 4.0, Vector3(x, 2.0, -22), wall_color)
	# ramp to balcony
	_box(self, Vector3(4, 0.5, 10), Vector3(0, 2.0, -14), metal)

	# Lighting accents (emissive strips on floor)
	_box(self, Vector3(2, 0.05, 2), Vector3(0, 0.02, 0), accent, false)
	for a in [Vector3(12,0,0), Vector3(-12,0,0), Vector3(0,0,12), Vector3(0,0,-12)]:
		_box(self, Vector3(1.5, 0.05, 1.5), Vector3(a.x, 0.02, a.z), Color(0.9,0.3,0.2), false)
