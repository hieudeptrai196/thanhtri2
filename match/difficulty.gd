class_name Difficulty
extends Resource
## How the run gets harder with route distance. All numbers live in a .tres so they can be tuned
## from playtests without code changes. Every function takes the distance in metres.

## Seconds between spawn waves at the start.
@export var spawn_interval_start: float = 4.5
## The interval is multiplied by this every kilometre.
@export_range(0.1, 1.0) var spawn_interval_decay_per_km: float = 0.7
@export var spawn_interval_min: float = 0.6
@export var max_alive_start: int = 30
@export var max_alive_per_km: int = 30
@export var max_alive_cap: int = 200
@export var health_bonus_per_km: float = 0.4
@export var damage_bonus_per_km: float = 0.25
## Enemies per spawn wave grow by this many per kilometre (rounded down), up to the cap.
@export var pack_growth_per_km: float = 0.75
@export var pack_size_cap: int = 6


func spawn_interval(distance: float) -> float:
	return maxf(spawn_interval_min, spawn_interval_start * pow(spawn_interval_decay_per_km, distance / 1000.0))


func max_alive(distance: float) -> int:
	return mini(max_alive_start + floori(max_alive_per_km * distance / 1000.0), max_alive_cap)


func health_multiplier(distance: float) -> float:
	return 1.0 + health_bonus_per_km * distance / 1000.0


func damage_multiplier(distance: float) -> float:
	return 1.0 + damage_bonus_per_km * distance / 1000.0


func pack_size(distance: float) -> int:
	return clampi(1 + floori(pack_growth_per_km * distance / 1000.0), 1, pack_size_cap)
