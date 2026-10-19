class_name Difficulty
extends Resource
## How the run gets harder with route distance and team size. All numbers live in a .tres so they
## can be tuned from playtests without code changes. Every function takes the distance in metres and
## the number of players in the run (1 = solo).

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
@export_group("Per extra player")
## Each player beyond the first adds this much to the spawn rate (0.35 → 5 players spawn 2.4× as often).
@export var spawn_rate_per_player: float = 0.35
## ...this many enemies to each wave (rounded down).
@export var pack_per_player: float = 0.5
## ...this fraction to the alive cap, which may then reach team_max_alive_cap.
@export var max_alive_per_player: float = 0.4
@export var team_max_alive_cap: int = 300
## ...this fraction to enemy health.
@export var health_per_player: float = 0.15


func spawn_interval(distance: float, team_size: int = 1) -> float:
	var solo := maxf(spawn_interval_min, spawn_interval_start * pow(spawn_interval_decay_per_km, distance / 1000.0))
	return solo / (1.0 + spawn_rate_per_player * _extra(team_size))


func max_alive(distance: float, team_size: int = 1) -> int:
	var solo := mini(max_alive_start + floori(max_alive_per_km * distance / 1000.0), max_alive_cap)
	if team_size <= 1:
		return solo
	return mini(roundi(solo * (1.0 + max_alive_per_player * _extra(team_size))), maxi(team_max_alive_cap, solo))


func health_multiplier(distance: float, team_size: int = 1) -> float:
	return (1.0 + health_bonus_per_km * distance / 1000.0) * (1.0 + health_per_player * _extra(team_size))


func damage_multiplier(distance: float) -> float:
	return 1.0 + damage_bonus_per_km * distance / 1000.0


func pack_size(distance: float, team_size: int = 1) -> int:
	return clampi(1 + floori(pack_growth_per_km * distance / 1000.0), 1, pack_size_cap) + floori(pack_per_player * _extra(team_size))


func _extra(team_size: int) -> int:
	return maxi(team_size - 1, 0)
