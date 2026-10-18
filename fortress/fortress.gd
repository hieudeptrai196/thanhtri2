class_name Fortress
extends AnimatableBody3D
## The moving citadel. Slows down as it loses health.

## Speed fraction at 0 HP, so the fortress never stops completely.
@export_range(0.0, 1.0, 0.05) var min_speed_ratio: float = 0.4

@onready var health: HealthComponent = $Health
@onready var follower: RouteFollower = $RouteFollower


func _ready() -> void:
	health.health_changed.connect(_on_health_changed)


func _on_health_changed(current: float, maximum: float) -> void:
	follower.speed_multiplier = lerpf(min_speed_ratio, 1.0, current / maximum)
