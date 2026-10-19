class_name FortressLook
extends Node3D
## The fortress's look, assembled from kit pieces (KayKit for now): a wooden war-wagon deck on six
## big wheels that turn with the speed, walls around the edge (a log palisade at the wood tier,
## stone walls above), corner towers with flags, a central tower carrying the crossbow and the
## ladder at the back. Purely visual: the fortress's collision stays a 10 × 5 × 10 box.

const KIT := "res://assets/kaykit/medieval/"
## Half the hull size and the deck height (wheels below it, walls on it).
const HALF := 4.6
const DECK_TOP := 2.2
const WHEEL_RADIUS := 1.35
const WHEEL_Z: Array[float] = [-3.4, 0.0, 3.4]

var _wheels: Array[Node3D] = []
var _walls: Node3D
var _tier: int = -1
var _torch_lights: Array[OmniLight3D] = []


func _ready() -> void:
	_build_deck()
	_build_wheels()
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var tower := _kit("building_tower_A_red", 1.8)
		tower.position = Vector3(corner.x * HALF, DECK_TOP, corner.y * HALF)
		add_child(tower)
		var flag := _kit("flag_red", 5.0)
		flag.position = tower.position + Vector3(0, 3.9, 0)
		add_child(flag)
		_add_torch(tower.position + Vector3(-corner.x * 0.9, 2.2, -corner.y * 0.9))
	var keep := _kit("building_tower_base_red", 2.0)
	keep.position = Vector3(0, DECK_TOP, 0)
	add_child(keep)
	var ladder := _kit("ladder", 6.5)
	ladder.position = Vector3(0, 0.0, 5.45)
	ladder.rotation_degrees.x = -10.0
	add_child(ladder)
	for side in [-1.0, 1.0]:
		var crates := _kit("crate_A_big", 3.0)
		crates.position = Vector3(side * 2.4, DECK_TOP, 2.6)
		add_child(crates)
		var barrel := _kit("barrel", 4.0)
		barrel.position = Vector3(side * 2.6, DECK_TOP, -2.4)
		add_child(barrel)
	set_tier(0)


func _process(_delta: float) -> void:
	# Torchlight flickers a little.
	var t := Time.get_ticks_msec() * 0.001
	for i in _torch_lights.size():
		_torch_lights[i].light_energy = 4.0 + sin(t * 9.0 + i * 1.7) * 0.25 + sin(t * 23.0 + i) * 0.15


func _add_torch(at: Vector3) -> void:
	var torch: Node3D = load("res://assets/kaykit/dungeon/torch_lit.glb").instantiate()
	torch.scale = Vector3.ONE * 1.4
	torch.position = at
	add_child(torch)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.28)
	light.omni_range = 13.0
	light.omni_attenuation = 1.4
	light.position = at + Vector3(0, 1.6, 0)
	add_child(light)
	_torch_lights.append(light)


## 0 = wood (log palisade), 1+ = stone walls.
func set_tier(tier: int) -> void:
	if tier == _tier:
		return
	_tier = tier
	if _walls:
		_walls.queue_free()
	_walls = Node3D.new()
	_walls.name = "Walls"
	add_child(_walls)
	for side in 4:
		var yaw := side * PI * 0.5
		var outward := Vector3(sin(yaw), 0, cos(yaw))
		var along := Vector3(cos(yaw), 0, -sin(yaw))
		for offset in [-2.3, 2.3]:
			var piece: Node3D
			if tier == 0:
				piece = _kit("fence_wood_straight", 4.2)
				piece.rotation.y = yaw + PI * 0.5
			else:
				piece = _kit("wall_straight", 2.3)
				piece.rotation.y = yaw
			piece.position = outward * HALF + along * offset + Vector3(0, DECK_TOP, 0)
			_walls.add_child(piece)


## Turns the wheels for a ground speed in metres per second.
func roll(speed: float, delta: float) -> void:
	for wheel in _wheels:
		wheel.rotate_object_local(Vector3.UP, -speed / WHEEL_RADIUS * delta)


func _build_deck() -> void:
	var deck := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(10.6, 1.0, 10.6)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.27, 0.15)
	wood.roughness = 0.9
	box.material = wood
	deck.mesh = box
	deck.position.y = DECK_TOP - 0.5
	add_child(deck)
	# Dark beams under the deck, so it reads as a wagon frame.
	for x in [-3.5, 0.0, 3.5]:
		var beam := MeshInstance3D.new()
		var beam_box := BoxMesh.new()
		beam_box.size = Vector3(0.5, 0.5, 11.2)
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color(0.22, 0.14, 0.08)
		beam_box.material = dark
		beam.mesh = beam_box
		beam.position = Vector3(x, DECK_TOP - 1.15, 0)
		add_child(beam)


func _build_wheels() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.35, 0.22, 0.12)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.25, 0.25, 0.27)
	iron.metallic = 0.6
	iron.roughness = 0.45
	for side in [-1.0, 1.0]:
		for z in WHEEL_Z:
			# Pivot laid on its side: the wheel's local Y is the axle.
			var wheel := Node3D.new()
			wheel.position = Vector3(side * (HALF + 0.75), WHEEL_RADIUS, z)
			wheel.rotation_degrees.z = 90.0
			add_child(wheel)
			var disc := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = WHEEL_RADIUS - 0.12
			cylinder.bottom_radius = WHEEL_RADIUS - 0.12
			cylinder.height = 0.5
			cylinder.radial_segments = 16
			cylinder.material = wood
			disc.mesh = cylinder
			wheel.add_child(disc)
			var rim := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = WHEEL_RADIUS - 0.18
			torus.outer_radius = WHEEL_RADIUS
			torus.rings = 24
			torus.material = iron
			rim.mesh = torus
			rim.scale = Vector3(1, 2.2, 1)
			wheel.add_child(rim)
			# Spokes as crossing bars, so the turning shows.
			for angle in [0.0, 60.0, 120.0]:
				var spoke := MeshInstance3D.new()
				var bar := BoxMesh.new()
				bar.size = Vector3(WHEEL_RADIUS * 2.0 - 0.3, 0.6, 0.22)
				bar.material = iron
				spoke.mesh = bar
				spoke.rotation_degrees.y = angle
				wheel.add_child(spoke)
			_wheels.append(wheel)


# A kit piece, scaled, with its footprint centred on the pivot and its bottom at y = 0 (the
# hexagon kit's pieces sit at tile edges, not at their own centre).
func _kit(piece: String, scale_factor: float) -> Node3D:
	var model: Node3D = load(KIT + piece + ".gltf").instantiate()
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var local := _transform_to(model, mesh) * mesh.get_aabb()
		bounds = local if first else bounds.merge(local)
		first = false
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * scale_factor
	var centre := bounds.get_center()
	model.position = Vector3(-centre.x, -bounds.position.y, -centre.z)
	holder.add_child(model)
	return holder


static func _transform_to(root: Node3D, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var current: Node = node
	while current != root and current is Node3D:
		xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform
