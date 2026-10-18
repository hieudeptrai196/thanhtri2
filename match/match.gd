extends Node3D
## Root of one run: wires the route, fortress and camera together and owns the match flow.

@onready var _route: Path3D = $Route
@onready var _fortress: Fortress = $Fortress
@onready var _follower: RouteFollower = $Fortress/RouteFollower
@onready var _warrior: Warrior = $Warrior
@onready var _status: Label = $DebugUI/Status
@onready var _fortress_info: Label = $DebugUI/FortressInfo


func _ready() -> void:
	_follower.reached_stop.connect(_on_reached_stop)
	_follower.departed.connect(_on_departed)
	_follower.reached_end.connect(_on_reached_end)
	_fortress.health.health_changed.connect(_on_fortress_health_changed)
	_warrior.input.ready_requested.connect(_on_ready_requested)
	_follower.start(_route)
	_status.text = "Đang chạy"
	_on_fortress_health_changed(_fortress.health.current, _fortress.health.max_health)


# TODO(giai đoạn 7): bỏ phím debug này khi đã có quái gây sát thương thật.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_K:
		_fortress.health.apply_damage(50.0, self)


func _on_fortress_health_changed(current: float, maximum: float) -> void:
	_fortress_info.text = "Pháo đài: %d / %d — tốc độ %d%%  [K: -50 máu]" % [
		current, maximum, roundi(_follower.speed_multiplier * 100.0)]


# Solo: one player's ready is enough. Multiplayer will wait for every player here.
func _on_ready_requested() -> void:
	if _follower.is_stopped:
		_follower.depart()


func _on_reached_stop(index: int) -> void:
	print("Match: tới điểm dừng %d" % index)
	_status.text = "Điểm dừng %d — bấm Space / Start để khởi hành" % (index + 1)


func _on_departed() -> void:
	print("Match: khởi hành")
	_status.text = "Đang chạy"


func _on_reached_end() -> void:
	print("Match: tới đích")
	_status.text = "Tới đích!"
