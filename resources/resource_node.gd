class_name ResourceNode
extends StaticBody3D
## A tree, coal deposit, ... Each weapon hit gives one unit to the attacker's inventory until depleted.

## After each unit taken (the host tells clients).
signal gathered(amount_left: int)

@export var resource_type: ResourceType
@export var amount: int = 5
## Noise made by each successful hit (chopping, digging).
@export var noise_per_hit: float = 0.3
@export_group("Look")
## Model files to pick from (by position, so every machine shows the same one); empty keeps the
## placeholder meshes under Visual.
@export var model_paths: PackedStringArray = []
@export var model_scale: float = 1.0
## Multiplies the model's colours (e.g. dark stone for coal).
@export var model_tint: Color = Color.WHITE
## Left behind for a while once depleted (a stump), or empty.
@export_file("*.gltf", "*.glb") var depleted_path: String = ""
## Seconds the depleted model stays.
const DEPLETED_SECONDS := 40.0

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group(&"resource_nodes")
	_hurtbox.hit_taken.connect(_on_hit_taken)
	_apply_look.call_deferred()  # after the content placer has positioned it


func _apply_look() -> void:
	if model_paths.is_empty() or not is_inside_tree():
		return
	for child in _visual.get_children():
		child.queue_free()
	var pick := absi(roundi(global_position.x * 7.0 + global_position.z * 13.0)) % model_paths.size()
	var model := _instance_model(model_paths[pick])
	model.rotation.y = fposmod(global_position.x * 1.7 + global_position.z * 0.9, TAU)
	_visual.add_child(model)


func _instance_model(path: String) -> Node3D:
	var model: Node3D = load(path).instantiate()
	model.scale = Vector3.ONE * model_scale
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if model_tint != Color.WHITE:
			var material := mesh.get_active_material(0).duplicate() as StandardMaterial3D
			material.albedo_color = model_tint
			mesh.material_override = material
	return model


# A stump (or the like) stays where the tree stood for a while; it is only decoration.
func _leave_depleted() -> void:
	Sfx.play(self, &"tree_fall" if resource_type and resource_type.id == &"wood" else &"smash", global_position)
	if depleted_path == "" or get_parent() == null:
		return
	var left := _instance_model(depleted_path)
	get_parent().add_child(left)
	left.global_transform = Transform3D(_visual.global_basis.orthonormalized(), global_position).scaled_local(Vector3.ONE * model_scale)
	left.reset_physics_interpolation()
	left.get_tree().create_timer(DEPLETED_SECONDS).timeout.connect(left.queue_free)


# Attackers are duck-typed: anything exposing an `inventory` can gather.
func _on_hit_taken(_amount: float, source: Node) -> void:
	gather(source, 1)


## Gives up to `count` units to `source`'s inventory (a Tiều phu's Bổ mạnh takes several). Host only.
func gather(source: Node, count: int) -> void:
	if not multiplayer.is_server() or amount <= 0:
		return
	var inventory: Inventory = source.get("inventory") if source else null
	if inventory == null:
		return
	var taken := inventory.add(resource_type.id, mini(count, amount))
	if taken == 0:
		return
	amount -= taken
	get_tree().call_group(&"noise", &"add", noise_per_hit)
	gathered.emit(amount)
	_bump()
	if amount <= 0:
		_leave_depleted()
		queue_free()


## Client: the host says how much is left.
func set_net_amount(value: int) -> void:
	if value < amount:
		_bump()
	amount = value
	if amount <= 0:
		_leave_depleted()
		queue_free()


func _bump() -> void:
	var is_wood := resource_type != null and resource_type.id == &"wood"
	Sfx.play(self, &"chop" if is_wood else &"mine", global_position)
	Burst.spawn(self, &"chips" if is_wood else &"dust", global_position + Vector3(0.0, 1.2, 0.0))
	_visual.scale = Vector3.ONE * 1.12
	create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.12)
