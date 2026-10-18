class_name CharmZone
extends Node3D
## Thầy pháp's Bùa trận: a circle on the ground that heals players and structures inside it every
## tick and slows monsters inside. Clients get one too (`simulated` off) that only shows the circle.

## Monsters inside move at this fraction of their speed.
const SLOW_FACTOR := 0.5
## Structures heal this much faster than players (they have more health).
const STRUCTURE_HEAL_SCALE := 1.5

var radius: float = 5.0
var duration: float = 6.0
## Health per second.
var heal_per_second: float = 8.0
var simulated: bool = true

var _left: float


func _ready() -> void:
	_left = duration
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.05
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.6, 0.4, 1.0, 0.3)
	disc.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = disc
	mesh.position.y = 0.06
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	if not simulated:
		return
	for player: Node3D in get_tree().get_nodes_in_group(&"players"):
		if player.get("is_alive") and _inside(player):
			player.health.heal(heal_per_second * delta)
	for structure: Structure in get_tree().get_nodes_in_group(&"structures"):
		if _inside(structure):
			structure.heal(heal_per_second * STRUCTURE_HEAL_SCALE * delta)
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if _inside(enemy):
			enemy.slow(SLOW_FACTOR, 0.2)


# Groups span the whole SceneTree (in-process co-op tests run two worlds in one tree).
func _inside(node: Node3D) -> bool:
	if node.get_world_3d() != get_world_3d():
		return false
	var offset := node.global_position - global_position
	return Vector2(offset.x, offset.z).length() <= radius
