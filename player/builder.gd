class_name Builder
extends Node3D
## One player's build mode. Picks a structure (number keys, or the radial menu on a gamepad), shows a
## ghost at the aim point coloured by placement (green / yellow = unpowered / red = blocked), asks
## the match to place it, and recovers foldable structures by holding the recover button.
## Rules and costs are decided by the match; this node only expresses intent and shows feedback.

signal place_requested(type: StructureType, point: Vector3)
signal recover_requested(structure: Structure)

@export var build_range: float = 6.0
@export var recover_range: float = 2.5
@export var recover_hold_time: float = 1.0
## Minimum stick tilt that selects a radial menu entry.
@export var radial_deadzone: float = 0.5

const GHOST_COLORS := {
	StructureNetwork.Placement.VALID: Color(0.3, 1.0, 0.4, 0.45),
	StructureNetwork.Placement.UNPOWERED: Color(1.0, 0.85, 0.2, 0.45),
	StructureNetwork.Placement.BLOCKED: Color(1.0, 0.25, 0.2, 0.45),
}

## Structure picked for building (null when not building). Carrying overrides it.
var selected: StructureType = null
var recover_progress: float = 0.0
## The recoverable structure in reach this tick, if any (for HUD prompts).
var recover_target: Structure = null
## The blueprint this player is hammering this tick, if any.
var hammer_target: Structure = null
var radial_open: bool = false
## Radial entry under the stick while the menu is open, or -1.
var radial_highlight: int = -1
var placement: StructureNetwork.Placement = StructureNetwork.Placement.BLOCKED

var network: StructureNetwork
var storage: Inventory

@onready var _warrior: Warrior = get_parent()
@onready var _ghost: MeshInstance3D = $Ghost
var _ghost_material := StandardMaterial3D.new()


func _ready() -> void:
	top_level = true
	_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.material_override = _ghost_material
	_ghost.visible = false


## Structure the ghost currently shows: what is carried, else what is selected.
func active_type() -> StructureType:
	return _warrior.carried_type if _warrior.carried_type else selected


func is_placing() -> bool:
	return active_type() != null


func ghost_point() -> Vector3:
	var origin := _warrior.global_position
	var offset := _warrior.input.aim_point - origin
	offset.y = 0.0
	return origin + offset.limit_length(build_range)


func _physics_process(delta: float) -> void:
	if network == null or not _warrior.is_alive:
		_ghost.visible = false
		radial_open = false
		recover_progress = 0.0
		return
	var input := _warrior.input
	_update_radial(input)
	if input.build_select >= 0 and input.build_select < StructureTypes.ALL.size():
		var picked := StructureTypes.ALL[input.build_select]
		selected = null if selected == picked else picked
	if input.cancel_pressed:
		selected = null

	var type := active_type()
	_ghost.visible = type != null
	if type:
		var point := ghost_point()
		placement = network.check_placement(type, point)
		# Blueprints are paid while hammering, so an empty storage does not block placing one.
		var shown := placement
		_ghost_material.albedo_color = GHOST_COLORS[shown]
		_ghost.global_position = Vector3(point.x, 0.05, point.z)
		_ghost.scale = Vector3(type.footprint_radius, 1.0, type.footprint_radius)
		if input.place_pressed and shown != StructureNetwork.Placement.BLOCKED and not radial_open:
			place_requested.emit(type, point)

	_update_hammer(input)
	_update_recover(input)


# Gamepad: hold the build button, tilt the right stick toward an entry, release to pick it.
func _update_radial(input: PlayerInput) -> void:
	if input.radial_held:
		radial_open = true
		radial_highlight = -1
		if input.aim_stick.length() >= radial_deadzone:
			var count := StructureTypes.ALL.size()
			var angle := fposmod(input.aim_stick.angle() + PI * 0.5, TAU)  # 0 = up, clockwise
			radial_highlight = int(round(angle / TAU * count)) % count
	elif radial_open:
		radial_open = false
		if radial_highlight >= 0:
			selected = StructureTypes.ALL[radial_highlight]
		radial_highlight = -1


# Hold interact next to a blueprint (outside build mode) to help finish it.
func _update_hammer(input: PlayerInput) -> void:
	hammer_target = null
	if is_placing() or _warrior.carried_type != null:
		return
	var blueprint := network.nearest_blueprint(_warrior.global_position, recover_range)
	if blueprint and input.interact_held:
		hammer_target = blueprint
		blueprint.add_hammer(_warrior.inventory)


# Recover progress lives on the structure, so helpers holding recover together finish sooner.
# With hands full only blueprints can be taken down.
func _update_recover(input: PlayerInput) -> void:
	recover_target = network.nearest_recoverable(_warrior.global_position, recover_range)
	if recover_target and recover_target.built and _warrior.carried_type != null:
		recover_target = null
	recover_progress = recover_target.recover_progress if recover_target else 0.0
	if recover_target == null or not input.recover_held:
		return
	recover_target.add_recover_helper()
	if recover_target.recover_progress >= recover_hold_time:
		recover_requested.emit(recover_target)
