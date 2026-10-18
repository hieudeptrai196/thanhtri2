class_name Fortress
extends AnimatableBody3D
## The moving citadel. Slows down as it loses health; repaired with resources from its storage.

## Speed fraction at 0 HP, so the fortress never stops completely.
@export_range(0.0, 1.0, 0.05) var min_speed_ratio: float = 0.4
@export var repair_resource: ResourceType
## Health restored per unit of repair_resource.
@export var repair_per_unit: float = 10.0
## Seconds between repair steps while someone keeps repairing.
@export var repair_interval: float = 0.2

@onready var health: HealthComponent = $Health
@onready var follower: RouteFollower = $RouteFollower
@onready var storage: Inventory = $Storage

var _repair_cooldown: float = 0.0


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)


func _physics_process(delta: float) -> void:
	_repair_cooldown = maxf(_repair_cooldown - delta, 0.0)


## Called every tick while at least one player repairs; spends one unit per step.
func tick_repair(_delta: float) -> void:
	if _repair_cooldown > 0.0 or health.current >= health.max_health:
		return
	_repair_cooldown = repair_interval
	if storage.spend({repair_resource.id: 1}):
		health.heal(repair_per_unit)


func _on_health_changed(current: float, maximum: float) -> void:
	follower.speed_multiplier = lerpf(min_speed_ratio, 1.0, current / maximum)
