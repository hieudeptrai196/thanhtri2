class_name Fortress
extends AnimatableBody3D
## The moving citadel. Burns coal from its storage to move (overdrive burns more for speed; with no
## coal it crawls) and slows down as it loses health; repaired with resources from its storage;
## upgraded through its body material tier. Starts with some resources in its storage.
## Defends itself a little: a weak crossbow on top hits enemies right at its walls, and thorns hurt
## whatever strikes it. Holding the line is still the job of field structures and players.

## Body material levels in order; the fortress starts at the first.
const TIERS: Array[FortressTier] = [
	preload("res://fortress/tiers/wood.tres"),
	preload("res://fortress/tiers/stone.tres"),
]

enum SpeedMode { MARCH, OVERDRIVE, OUT_OF_FUEL }

## Speed fraction at 0 HP, so the fortress never stops completely.
@export_range(0.0, 1.0, 0.05) var min_speed_ratio: float = 0.4
@export var repair_resource: ResourceType
## Health restored per unit of repair_resource.
@export var repair_per_unit: float = 10.0
## Seconds between repair steps while someone keeps repairing.
@export var repair_interval: float = 0.2
## Damage reflected to an enemy each time it hits the fortress.
@export var thorns_damage: float = 3.0
## Put into the storage at the start of a run, keyed by ResourceType.id.
@export var starting_resources: Dictionary = {&"wood": 30, &"coal": 15}
@export var fuel_resource: ResourceType
## Fuel units burned per second while marching / in overdrive.
@export var fuel_per_second: float = 0.125
@export var overdrive_fuel_per_second: float = 0.6
## Speed multipliers per mode (combined with the health multiplier).
@export var overdrive_speed: float = 1.6
@export var out_of_fuel_speed: float = 0.35

@onready var health: HealthComponent = $Health
@onready var follower: RouteFollower = $RouteFollower
@onready var storage: Inventory = $Storage
@onready var service_zone: ServiceZone = $ServiceZone
@onready var crossbow: AutoShooter = $Crossbow
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _body_mesh: MeshInstance3D = $Body

var tier_index: int = 0
## Players toggle this; it only applies while there is fuel.
var overdrive: bool = false
var speed_mode: SpeedMode = SpeedMode.MARCH

var _repair_cooldown: float = 0.0
## Fuel burned but not yet taken out of storage (whole units are taken).
var _fuel_owed: float = 0.0


func _ready() -> void:
	health.health_changed.connect(func(_current: float, _maximum: float) -> void: _update_speed())
	_apply_tier(TIERS[tier_index])
	storage.add_all(starting_resources)
	_hurtbox.hit_taken.connect(_on_hit_taken)


func _physics_process(delta: float) -> void:
	_repair_cooldown = maxf(_repair_cooldown - delta, 0.0)
	_burn_fuel(delta)
	_update_speed()


func fuel_left() -> int:
	return storage.get_amount(fuel_resource.id)


## Seconds of marching left at the current burn rate.
func fuel_seconds_left() -> float:
	var rate := overdrive_fuel_per_second if overdrive else fuel_per_second
	return (fuel_left() - _fuel_owed) / rate


func _burn_fuel(delta: float) -> void:
	if follower.is_stopped:
		return
	_fuel_owed += (overdrive_fuel_per_second if overdrive else fuel_per_second) * delta
	while _fuel_owed >= 1.0 and storage.spend({fuel_resource.id: 1}):
		_fuel_owed -= 1.0
	# Out of fuel once a whole unit is owed and none is left; refuelling clears it next tick.
	if _fuel_owed >= 1.0:
		speed_mode = SpeedMode.OUT_OF_FUEL
		_fuel_owed = 1.0
	else:
		speed_mode = SpeedMode.OVERDRIVE if overdrive else SpeedMode.MARCH


func _update_speed() -> void:
	var health_factor := lerpf(min_speed_ratio, 1.0, health.get_ratio())
	var mode_factor := 1.0
	match speed_mode:
		SpeedMode.OVERDRIVE:
			mode_factor = overdrive_speed
		SpeedMode.OUT_OF_FUEL:
			mode_factor = out_of_fuel_speed
	follower.speed_multiplier = health_factor * mode_factor


func get_tier() -> FortressTier:
	return TIERS[tier_index]


## The tier an upgrade would reach, or null at the top.
func get_next_tier() -> FortressTier:
	return TIERS[tier_index + 1] if tier_index + 1 < TIERS.size() else null


func upgrade_tier() -> bool:
	var next := get_next_tier()
	if next == null or not storage.spend(next.cost):
		return false
	tier_index += 1
	_apply_tier(next)
	return true


## Called every tick while at least one player repairs; spends one unit per step.
func tick_repair(_delta: float) -> void:
	if _repair_cooldown > 0.0 or health.current >= health.max_health:
		return
	_repair_cooldown = repair_interval
	if storage.spend({repair_resource.id: 1}):
		health.heal(repair_per_unit)


func _apply_tier(tier: FortressTier) -> void:
	health.set_max_health(tier.max_health)
	var material := StandardMaterial3D.new()
	material.albedo_color = tier.color
	_body_mesh.material_override = material


# Thorns: an attacker with a Hurtbox of its own takes a little damage back (bombs have none).
func _on_hit_taken(_amount: float, source: Node) -> void:
	if thorns_damage <= 0.0 or not is_instance_valid(source) or source == self:
		return
	var attacker_hurtbox := source.get_node_or_null(^"Hurtbox") as Hurtbox
	if attacker_hurtbox:
		attacker_hurtbox.take_hit(thorns_damage, self)

