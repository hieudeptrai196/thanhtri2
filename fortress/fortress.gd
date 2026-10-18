class_name Fortress
extends AnimatableBody3D
## The moving citadel. Slows down as it loses health; repaired with resources from its storage;
## upgraded through its body material tier. Starts with some resources in its storage.

## Body material levels in order; the fortress starts at the first.
const TIERS: Array[FortressTier] = [
	preload("res://fortress/tiers/wood.tres"),
	preload("res://fortress/tiers/stone.tres"),
]

## Speed fraction at 0 HP, so the fortress never stops completely.
@export_range(0.0, 1.0, 0.05) var min_speed_ratio: float = 0.4
@export var repair_resource: ResourceType
## Health restored per unit of repair_resource.
@export var repair_per_unit: float = 10.0
## Seconds between repair steps while someone keeps repairing.
@export var repair_interval: float = 0.2
## Put into the storage at the start of a run, keyed by ResourceType.id.
@export var starting_resources: Dictionary = {&"wood": 30}

@onready var health: HealthComponent = $Health
@onready var follower: RouteFollower = $RouteFollower
@onready var storage: Inventory = $Storage
@onready var service_zone: ServiceZone = $ServiceZone
@onready var _body_mesh: MeshInstance3D = $Body

var tier_index: int = 0

var _repair_cooldown: float = 0.0


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)
	_apply_tier(TIERS[tier_index])
	storage.add_all(starting_resources)


func _physics_process(delta: float) -> void:
	_repair_cooldown = maxf(_repair_cooldown - delta, 0.0)


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


func _on_health_changed(current: float, maximum: float) -> void:
	follower.speed_multiplier = lerpf(min_speed_ratio, 1.0, current / maximum)
