extends Node3D
## Root of one run: wires the route, fortress, players and spawner together and owns the match flow.

## 0 picks a random seed each run.
@export var rng_seed: int = 0
## Seconds before a fallen warrior returns next to the fortress.
@export var respawn_delay: float = 3.0

@onready var _route: Path3D = $Route
@onready var _fortress: Fortress = $Fortress
@onready var _follower: RouteFollower = $Fortress/RouteFollower
@onready var _warrior: Warrior = $Warrior
@onready var _spawner: Spawner = $Spawner
@onready var _status: Label = $DebugUI/Status
@onready var _fortress_info: Label = $DebugUI/FortressInfo
@onready var _player_info: Label = $DebugUI/PlayerInfo

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	if rng_seed != 0:
		rng.seed = rng_seed
	_follower.reached_stop.connect(_on_reached_stop)
	_follower.departed.connect(_on_departed)
	_follower.reached_end.connect(_on_reached_end)
	_fortress.health.health_changed.connect(_on_fortress_health_changed)
	_warrior.input.ready_requested.connect(_on_ready_requested)
	_warrior.health.died.connect(_on_warrior_died)

	var players: Array[Node3D] = [_warrior]
	_spawner.setup(rng, _fortress, players)
	_spawner.active = true
	_follower.start(_route)

	_status.text = "Đang chạy"
	_on_fortress_health_changed(_fortress.health.current, _fortress.health.max_health)


func _process(_delta: float) -> void:
	var warrior_text := "Chiến binh: %d / %d" % [_warrior.health.current, _warrior.health.max_health]
	if not _warrior.is_alive:
		warrior_text = "Chiến binh đã ngã — đang hồi sinh"
	_player_info.text = "%s   |   Quái: %d" % [warrior_text, _spawner.alive_count()]


# TODO(giai đoạn 7): bỏ phím debug này khi đã có quái gây sát thương thật.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		_fortress.health.apply_damage(50.0, self)


# Solo: one player's ready is enough. Multiplayer will wait for every player here.
func _on_ready_requested() -> void:
	if _follower.is_stopped:
		_follower.depart()


func _on_warrior_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	_warrior.respawn_at(_fortress.global_transform * Vector3(8.0, 0.0, 0.0))


func _on_fortress_health_changed(current: float, maximum: float) -> void:
	_fortress_info.text = "Pháo đài: %d / %d — tốc độ %d%%  [K: -50 máu]" % [
		current, maximum, roundi(_follower.speed_multiplier * 100.0)]


# Stops are safe zones: no spawning and no monsters left around.
func _on_reached_stop(index: int) -> void:
	print("Match: tới điểm dừng %d" % index)
	_spawner.active = false
	_spawner.clear()
	_status.text = "Điểm dừng %d — bấm Space / Start để khởi hành" % (index + 1)


func _on_departed() -> void:
	print("Match: khởi hành")
	_spawner.active = true
	_status.text = "Đang chạy"


func _on_reached_end() -> void:
	print("Match: tới đích")
	_spawner.active = false
	_spawner.clear()
	_status.text = "Tới đích!"
