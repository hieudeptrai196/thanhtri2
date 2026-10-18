class_name NoiseMeter
extends Node
## How much noise the expedition makes (0–100). Grows while the fortress moves (more in overdrive)
## and with noisy actions; stops calm it down. Higher noise means denser enemy waves; at 100 the run
## enters pursuit until the next stop. Noise sources call `add` through the "noise" group so they do
## not need a reference to the match.

enum Level { QUIET, PROBING, SWARM, HEAVY, PURSUIT }

signal level_changed(level: Level)

const MAX := 100.0
## Lower bounds of each level (PURSUIT = MAX).
const THRESHOLDS: Array[float] = [0.0, 25.0, 50.0, 75.0, 100.0]

@export var passive_per_second: float = 0.3
@export var overdrive_per_second: float = 1.2
## Noise is lowered to at most this when the fortress reaches a stop.
@export var stop_calm_to: float = 18.0
## Spawn rate multiplier at full noise (1 at silence).
@export var max_spawn_rate: float = 2.0
## Extra enemies per wave at SWARM / HEAVY / PURSUIT.
@export var extra_pack: Array[int] = [0, 0, 1, 2, 3]

var value: float = 0.0
## Seconds spent in pursuit (pursuit escalates the longer it lasts).
var pursuit_time: float = 0.0

var _fortress: Fortress
var _level: Level = Level.QUIET


func setup(fortress: Fortress) -> void:
	_fortress = fortress
	add_to_group(&"noise")
	fortress.follower.reached_stop.connect(func(_index: int) -> void: calm())


func _physics_process(delta: float) -> void:
	if _fortress == null or _fortress.follower.is_stopped:
		return
	add((passive_per_second + (overdrive_per_second if _fortress.overdrive else 0.0)) * delta)
	if level() == Level.PURSUIT:
		pursuit_time += delta


## Adds noise (called directly or via the "noise" group).
func add(amount: float) -> void:
	if _fortress != null and _fortress.follower.is_stopped:
		return
	value = clampf(value + amount, 0.0, MAX)
	_update_level()


## Client side: takes the host's noise.
func set_net_state(new_value: float, new_pursuit_time: float) -> void:
	value = new_value
	pursuit_time = new_pursuit_time
	_update_level()


func calm() -> void:
	value = minf(value, stop_calm_to)
	pursuit_time = 0.0
	_update_level()


func level() -> Level:
	for i in range(THRESHOLDS.size() - 1, -1, -1):
		if value >= THRESHOLDS[i]:
			return i as Level
	return Level.QUIET


func spawn_rate_multiplier() -> float:
	return lerpf(1.0, max_spawn_rate, value / MAX) * (1.0 + pursuit_time / 30.0 if level() == Level.PURSUIT else 1.0)


func extra_pack_size() -> int:
	return extra_pack[level()]


## Enemies get faster the longer the pursuit lasts (+10% per 10 s, up to +50%).
func enemy_speed_multiplier() -> float:
	return 1.0 + minf(pursuit_time / 100.0, 0.5) if level() == Level.PURSUIT else 1.0


func _update_level() -> void:
	var now := level()
	if now != _level:
		_level = now
		level_changed.emit(now)
